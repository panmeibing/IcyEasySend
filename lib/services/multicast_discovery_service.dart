import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/discovered_device.dart';
import '../models/multicast_announcement.dart';
import '../utils/constants.dart';
import '../utils/http_helper.dart';
import '../utils/log_util.dart';
import '../utils/multicast_lock_helper.dart';
import '../utils/multicast_socket_options.dart';
import '../utils/network_util.dart';
import '../utils/ohos_platform.dart';
import 'identity_service.dart';

/// UDP multicast / broadcast LAN discovery (LocalSend-style).
///
/// An announcement is one UDP datagram to [AppConstants.multicastGroup].
/// Every peer answers with a single HTTP POST to `/discover/register`
/// (UDP unicast is only a fallback). That replaces probing every address
/// on the subnet.
///
/// - Listener binds every port in [AppConstants.discoveryUdpPorts], so a
///   peer whose HTTP server moved off [AppConstants.defaultPort] is still
///   heard
/// - Each announcement is sent once per interface (`IP_MULTICAST_IF`)
/// - Background announcements while the server is running
class MulticastDiscoveryService {
  static final MulticastDiscoveryService instance =
      MulticastDiscoveryService._();

  MulticastDiscoveryService._();

  final String logTag = LogTags.network;
  final StreamController<DiscoveredDevice> _deviceController =
      StreamController<DiscoveredDevice>.broadcast();

  final List<RawDatagramSocket> _sockets = [];
  List<String> _listenerInterfaceIps = [];

  /// deviceId@ip → last time we answered / emitted that peer.
  ///
  /// One announcement is delivered once per bound port. Without this, a
  /// single shout turns into a burst of identical HTTP registers.
  final Map<String, DateTime> _recentPeers = {};

  String? _deviceId;
  String? _deviceName;
  int? _httpPort;
  Set<String> _localIps = {};
  bool _serverRunning = false;
  bool _listening = false;
  bool _acceptingRegistrations = false;
  int _registrationHolders = 0;
  bool _multicastLockHeld = false;
  Timer? _announceTimer;

  Stream<DiscoveredDevice> get deviceStream => _deviceController.stream;

  Future<void> configure({
    required String deviceId,
    required String deviceName,
    required int serverPort,
    required Set<String> localIps,
    required bool serverRunning,
  }) async {
    _deviceId = deviceId;
    _deviceName = deviceName;
    _httpPort = serverPort;
    _localIps = localIps;
    _serverRunning = serverRunning;
  }

  Future<void> startListener() async {
    if (_httpPort == null) {
      LogUtil.wTag(logTag, '组播配置未完成，无法启动监听');
      return;
    }

    if (_listening && _sockets.isNotEmpty) {
      if (_serverRunning) {
        _startPeriodicAnnouncements();
      }
      return;
    }

    await _acquireMulticastLock();
    await _closeSocket();
    await _bindListenerSocket();

    if (_sockets.isEmpty) {
      await _releaseMulticastLock();
      LogUtil.wTag(
        logTag,
        'UDP 发现监听启动失败：请检查防火墙是否允许 UDP '
        '${AppConstants.defaultPort}-${AppConstants.maxServerPort}',
      );
      return;
    }

    _listening = true;
    final boundPorts = _sockets.map((socket) => socket.port).join(', ');
    LogUtil.iTag(
      logTag,
      'UDP 发现监听已启动 (multicast: ${AppConstants.multicastGroup}, '
      'ports: $boundPorts, interfaces: ${_listenerInterfaceIps.length})',
    );

    if (_serverRunning) {
      _startPeriodicAnnouncements();
    }
  }

  Future<void> stopListener() async {
    _listening = false;
    _stopPeriodicAnnouncements();
    await _closeSocket();
    _recentPeers.clear();
    await _releaseMulticastLock();
  }

  /// Keeps accepting `/discover/register` until [stopAcceptingRegistrations].
  ///
  /// The announcement burst outlives the grace period: a peer that only
  /// hears the later repeat can still register while the HTTP fallback runs.
  Future<void> runDiscoveryRound({
    required Set<String> localIps,
    Duration grace = AppConstants.deviceScanMulticastGrace,
    bool Function()? isCancelled,
    bool Function()? hasPeer,
  }) async {
    _localIps = localIps;
    _holdRegistrations();

    if (!_listening || _sockets.isEmpty) {
      await startListener();
    }

    // Fire-and-forget. Awaiting it would block the scan for the whole
    // burst (~2.6s) before the grace period even started.
    unawaited(sendAnnouncement(isCancelled: isCancelled, burst: true));

    await _sleepUnless(grace, isCancelled);
    if (isCancelled?.call() == true) {
      return;
    }

    if (hasPeer?.call() == true) {
      await _sleepUnless(AppConstants.deviceScanMulticastTailWait, isCancelled);
    }
  }

  void stopAcceptingRegistrations() {
    if (_registrationHolders > 0) {
      _registrationHolders--;
    }
    _acceptingRegistrations = _registrationHolders > 0;
  }

  void _holdRegistrations() {
    _registrationHolders++;
    _acceptingRegistrations = true;
  }

  Future<void> _sleepUnless(
    Duration duration,
    bool Function()? isCancelled,
  ) async {
    final deadline = DateTime.now().add(duration);
    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled?.call() == true) {
        return;
      }
      final remaining = deadline.difference(DateTime.now());
      final step = remaining < const Duration(milliseconds: 50)
          ? remaining
          : const Duration(milliseconds: 50);
      if (step <= Duration.zero) {
        return;
      }
      await Future.delayed(step);
    }
  }

  bool notifyDeviceFromRegister(DiscoveredDevice device, String deviceId) {
    if (!_acceptingRegistrations || !_isPeerDevice(deviceId, device.ip)) {
      return false;
    }

    _deviceController.add(device);
    return true;
  }

  Future<void> sendAnnouncement({
    bool Function()? isCancelled,
    bool burst = true,
  }) async {
    final payload = _buildAnnouncement(announcement: true);
    if (payload == null) {
      return;
    }

    if (!burst) {
      final sent = await _sendMulticastPacket(payload);
      LogUtil.dTag(logTag, '后台 UDP announcement ($sent 次发送)');
      return;
    }

    for (final delayMs in AppConstants.multicastAnnouncementDelaysMs) {
      if (isCancelled?.call() == true) {
        return;
      }

      await Future.delayed(Duration(milliseconds: delayMs));
      if (isCancelled?.call() == true) {
        return;
      }

      final sent = await _sendMulticastPacket(payload);
      LogUtil.dTag(
        logTag,
        '发送 UDP 发现 announcement (multicast + broadcast, $sent 次发送)',
      );
    }
  }

  void _startPeriodicAnnouncements() {
    _announceTimer?.cancel();
    if (!_serverRunning) {
      return;
    }

    unawaited(sendAnnouncement(burst: false));

    _announceTimer = Timer.periodic(AppConstants.multicastBackgroundInterval, (
      _,
    ) {
      if (_serverRunning) {
        unawaited(sendAnnouncement(burst: false));
      }
    });
  }

  void _stopPeriodicAnnouncements() {
    _announceTimer?.cancel();
    _announceTimer = null;
  }

  Future<void> _bindListenerSocket() async {
    final interfaces = await NetworkUtil.getLanNetworkInterfaces();
    if (interfaces.isEmpty) {
      LogUtil.wTag(logTag, '未找到可用于 UDP 发现的网络接口');
      return;
    }

    final interfaceIps = <String>[];
    for (final interface in interfaces) {
      final interfaceIp = NetworkUtil.getPrimaryPrivateIpv4(interface);
      if (interfaceIp != null) {
        interfaceIps.add(interfaceIp);
      }
    }

    if (interfaceIps.isEmpty) {
      LogUtil.wTag(logTag, '未找到可用于 UDP 发现的私有 IPv4 地址');
      return;
    }

    _listenerInterfaceIps = interfaceIps;
    final group = InternetAddress(AppConstants.multicastGroup);

    for (final port in AppConstants.discoveryUdpPorts) {
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          port,
          reuseAddress: true,
          reusePort: _supportsReusePort,
        );
      } catch (e) {
        LogUtil.wTag(logTag, 'UDP 绑定失败 (0.0.0.0:$port): $e');
        continue;
      }

      socket.broadcastEnabled = true;

      var joinedAny = false;
      for (final interface in interfaces) {
        if (NetworkUtil.getPrimaryPrivateIpv4(interface) == null) {
          continue;
        }

        try {
          socket.joinMulticast(group, interface);
          joinedAny = true;
        } catch (e) {
          LogUtil.wTag(
            logTag,
            '接口 ${interface.name} 加入组播 ${AppConstants.multicastGroup}:$port 失败: $e',
          );
        }
      }

      if (!joinedAny) {
        socket.close();
        continue;
      }

      _attachSocket(socket);
      _sockets.add(socket);
      LogUtil.dTag(
        logTag,
        'UDP 监听: 0.0.0.0:$port (${interfaceIps.join(", ")})',
      );
    }
  }

  void _attachSocket(RawDatagramSocket socket) {
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) {
          return;
        }

        Datagram? datagram;
        while ((datagram = socket.receive()) != null) {
          _handleDatagram(datagram!);
        }
      },
      onError: (Object error) {
        LogUtil.wTag(logTag, 'UDP 监听错误 (port ${socket.port}): $error');
      },
    );
  }

  Future<void> _closeSocket() async {
    for (final socket in _sockets) {
      try {
        socket.close();
      } catch (_) {}
    }
    _sockets.clear();
    _listenerInterfaceIps = [];
  }

  void _handleDatagram(Datagram datagram) {
    final announcement = MulticastAnnouncement.tryParse(datagram.data);
    if (announcement == null) {
      return;
    }

    final sourceIp = datagram.address.address;
    if (!_isPeerDevice(announcement.deviceId, sourceIp)) {
      return;
    }

    // The same shout is delivered once per bound port. Collapse that fan-out,
    // but keep answering a later repeat (those are hundreds of ms apart).
    if (!_rememberPeer(announcement.deviceId, sourceIp)) {
      return;
    }

    LogUtil.dTag(
      logTag,
      '收到 UDP 包 $sourceIp:${datagram.port} (${datagram.data.length} bytes)',
    );

    final device = DiscoveredDevice(
      ip: sourceIp,
      port: announcement.port,
      deviceName: announcement.deviceName,
      deviceId: announcement.deviceId,
      publicKey: announcement.publicKey,
    );

    if (announcement.announcement && _serverRunning) {
      unawaited(
        _sendResponse(
          replyTo: datagram.address,
          scannerHttpPort: announcement.port,
        ),
      );
      LogUtil.dTag(
        logTag,
        '已响应 UDP announcement: ${device.displayAddress} '
        '(tcp -> $sourceIp:${announcement.port})',
      );
    }

    if (_emitPeerDevice(device, announcement.deviceId)) {
      LogUtil.iTag(
        logTag,
        '[DISCOVER/UDP] ${device.deviceName} (${device.displayAddress})',
      );
    }
  }

  bool _rememberPeer(String deviceId, String ip) {
    final now = DateTime.now();
    _recentPeers.removeWhere(
      (_, seen) => now.difference(seen) > const Duration(seconds: 5),
    );

    final key = '$deviceId@$ip';
    final seen = _recentPeers[key];
    if (seen != null &&
        now.difference(seen) < const Duration(milliseconds: 150)) {
      return false;
    }
    _recentPeers[key] = now;
    return true;
  }

  bool _emitPeerDevice(DiscoveredDevice device, String deviceId) {
    if (!_isPeerDevice(deviceId, device.ip)) {
      return false;
    }

    _deviceController.add(device);
    return true;
  }

  bool _isPeerDevice(String deviceId, String ip) {
    return deviceId != _deviceId && !_localIps.contains(ip);
  }

  Future<void> _sendResponse({
    required InternetAddress replyTo,
    required int scannerHttpPort,
  }) async {
    final payload = _buildAnnouncement(announcement: false);
    if (payload == null) {
      return;
    }

    await Future.wait([
      _sendHttpRegister(replyTo.address, scannerHttpPort, payload),
      _sendUnicast(payload, replyTo),
    ]);
    // UDP fallback for peers that never see the HTTP register.
    await _sendMulticastPacket(payload);
  }

  List<int>? _buildAnnouncement({required bool announcement}) {
    if (_deviceId == null || _httpPort == null || _deviceName == null) {
      LogUtil.wTag(logTag, '组播配置未完成，跳过发送 announcement');
      return null;
    }

    return MulticastAnnouncement.forDevice(
      deviceName: _deviceName!,
      deviceId: _deviceId!,
      port: _httpPort!,
      announcement: announcement,
      // Null until the identity has loaded; peers treat a missing key as
      // "cannot pair yet" and the next announcement will carry it.
      publicKey: IdentityService.instance.publicKeyBase64OrNull,
    ).toBytes();
  }

  Future<void> _sendHttpRegister(
    String scannerIp,
    int scannerHttpPort,
    List<int> payload,
  ) async {
    final url = NetworkUtil.buildHttpUrl(
      scannerIp,
      '/discover/register',
      targetPort: scannerHttpPort,
    );

    final result = await HttpHelper.post(
      url,
      body: utf8.decode(payload),
      headers: {'Content-Type': 'application/json'},
      timeout: Duration(
        milliseconds: AppConstants.deviceScanDiscoveryTimeoutMs,
      ),
    );

    if (result.isSuccess) {
      LogUtil.dTag(logTag, 'HTTP 发现注册成功 -> $scannerIp:$scannerHttpPort');
    } else {
      LogUtil.dTag(
        logTag,
        'HTTP 发现注册失败 -> $scannerIp:$scannerHttpPort: ${result.errorMessage}',
      );
    }
  }

  Future<void> _sendUnicast(List<int> payload, InternetAddress target) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      // Announcements leave from an ephemeral port, so a reply to
      // datagram.port is discarded. Answer every discovery port instead:
      // that is where the scanner is listening.
      for (final port in AppConstants.discoveryUdpPorts) {
        socket.send(payload, target, port);
      }
    } catch (e) {
      LogUtil.wTag(logTag, '单播回复失败 -> ${target.address}: $e');
    } finally {
      socket?.close();
    }
  }

  Future<int> _sendMulticastPacket(List<int> payload) async {
    final multicast = InternetAddress(AppConstants.multicastGroup);
    final ports = AppConstants.discoveryUdpPorts.toList();
    var sentCount = 0;

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      MulticastSocketOptions.setMulticastTtl(
        socket,
        MulticastSocketOptions.defaultMulticastTtl,
      );
      socket.broadcastEnabled = true;

      final interfaces = await NetworkUtil.getLanNetworkInterfaces();
      if (interfaces.isEmpty) {
        sentCount += _sendOnSocket(socket, payload, multicast, ports);
        sentCount += _sendOnSocket(
          socket,
          payload,
          InternetAddress('255.255.255.255'),
          ports,
        );
        return sentCount;
      }

      for (final interface in interfaces) {
        final interfaceIp = NetworkUtil.getPrimaryPrivateIpv4(interface);
        if (interfaceIp == null) {
          continue;
        }

        MulticastSocketOptions.setMulticastInterface(
          socket,
          InternetAddress(interfaceIp),
        );
        sentCount += _sendOnSocket(socket, payload, multicast, ports);

        final broadcast = NetworkUtil.getSubnetBroadcast(interfaceIp);
        if (broadcast != null) {
          sentCount += _sendOnSocket(
            socket,
            payload,
            InternetAddress(broadcast),
            ports,
          );
        }
      }

      sentCount += _sendOnSocket(
        socket,
        payload,
        InternetAddress('255.255.255.255'),
        ports,
      );
    } catch (e) {
      LogUtil.wTag(logTag, '发送 UDP 发现包失败: $e');
    } finally {
      socket?.close();
    }

    return sentCount;
  }

  int _sendOnSocket(
    RawDatagramSocket socket,
    List<int> payload,
    InternetAddress address,
    List<int> ports,
  ) {
    var sent = 0;
    for (final port in ports) {
      try {
        if (socket.send(payload, address, port) > 0) {
          sent++;
        }
      } catch (_) {}
    }
    return sent;
  }

  Future<void> _acquireMulticastLock() async {
    if (_multicastLockHeld) {
      return;
    }
    await MulticastLockHelper.acquire();
    _multicastLockHeld = true;
  }

  Future<void> _releaseMulticastLock() async {
    if (!_multicastLockHeld) {
      return;
    }
    await MulticastLockHelper.release();
    _multicastLockHeld = false;
  }

  bool get _supportsReusePort =>
      Platform.isLinux || Platform.isAndroid || isOhosPlatform;
}
