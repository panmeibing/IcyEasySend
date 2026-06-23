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

/// UDP multicast / broadcast LAN discovery (LocalSend-style).
///
/// - UDP and HTTP share the same port
/// - Listener binds to 0.0.0.0 with SO_REUSEADDR
/// - Multicast sends use a short-lived socket with TTL=2
/// - Background announcements while the server is running
class MulticastDiscoveryService {
  static final MulticastDiscoveryService instance =
      MulticastDiscoveryService._();

  MulticastDiscoveryService._();

  final String logTag = LogTags.network;
  final StreamController<DiscoveredDevice> _deviceController =
      StreamController<DiscoveredDevice>.broadcast();

  RawDatagramSocket? _socket;
  List<String> _listenerInterfaceIps = [];

  String? _deviceId;
  String? _deviceName;
  int? _httpPort;
  int? _boundPort;
  Set<String> _localIps = {};
  bool _serverRunning = false;
  bool _listening = false;
  bool _acceptingRegistrations = false;
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

    if (_listening && _socket != null && _boundPort == _httpPort) {
      if (_serverRunning) {
        _startPeriodicAnnouncements();
      }
      return;
    }

    await _acquireMulticastLock();
    await _closeSocket();
    await _bindListenerSocket();

    if (_socket == null) {
      await _releaseMulticastLock();
      LogUtil.wTag(
        logTag,
        'UDP 发现监听启动失败：请检查防火墙是否允许 UDP $_httpPort',
      );
      return;
    }

    _listening = true;
    LogUtil.iTag(
      logTag,
      'UDP 发现监听已启动 (multicast: ${AppConstants.multicastGroup}, '
      'port: $_httpPort, interfaces: ${_listenerInterfaceIps.length})',
    );

    if (_serverRunning) {
      _startPeriodicAnnouncements();
    }
  }

  Future<void> stopListener() async {
    _listening = false;
    _stopPeriodicAnnouncements();
    await _closeSocket();
    _boundPort = null;
    await _releaseMulticastLock();
  }

  Future<void> runDiscoveryRound({
    required Set<String> localIps,
    Duration waitDuration = AppConstants.deviceScanMulticastWait,
    bool Function()? isCancelled,
  }) async {
    _localIps = localIps;
    _acceptingRegistrations = true;

    try {
      if (!_listening || _boundPort != _httpPort) {
        await startListener();
      }

      await sendAnnouncement(isCancelled: isCancelled, burst: true);
      await Future.delayed(waitDuration);
      await Future.delayed(AppConstants.deviceScanMulticastTailWait);
    } finally {
      _acceptingRegistrations = false;
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

    _announceTimer = Timer.periodic(
      AppConstants.multicastBackgroundInterval,
      (_) {
        if (_serverRunning) {
          unawaited(sendAnnouncement(burst: false));
        }
      },
    );
  }

  void _stopPeriodicAnnouncements() {
    _announceTimer?.cancel();
    _announceTimer = null;
  }

  Future<void> _bindListenerSocket() async {
    final port = _httpPort!;
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
      return;
    }

    socket.broadcastEnabled = true;

    var joinedAny = false;
    for (final interface in interfaces) {
      if (NetworkUtil.getPrimaryPrivateIpv4(interface) == null) {
        continue;
      }

      try {
        socket.joinMulticast(
          InternetAddress(AppConstants.multicastGroup),
          interface,
        );
        joinedAny = true;
      } catch (e) {
        LogUtil.wTag(
          logTag,
          '接口 ${interface.name} 加入组播 ${AppConstants.multicastGroup} 失败: $e',
        );
      }
    }

    if (!joinedAny) {
      socket.close();
      return;
    }

    _boundPort = port;
    _socket = socket;
    _listenerInterfaceIps = interfaceIps;

    LogUtil.dTag(
      logTag,
      'UDP 监听: 0.0.0.0:$port (${interfaceIps.join(", ")})',
    );

    socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      Datagram? datagram;
      while ((datagram = socket?.receive()) != null) {
        _handleDatagram(datagram!);
      }
    });
  }

  Future<void> _closeSocket() async {
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    _listenerInterfaceIps = [];
  }

  void _handleDatagram(Datagram datagram) {
    LogUtil.dTag(
      logTag,
      '收到 UDP 包 ${datagram.address.address}:${datagram.port} '
      '(${datagram.data.length} bytes)',
    );

    final announcement = MulticastAnnouncement.tryParse(datagram.data);
    if (announcement == null) {
      return;
    }

    final device = DiscoveredDevice(
      ip: datagram.address.address,
      port: announcement.port,
      deviceName: announcement.deviceName,
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
        '(tcp -> ${datagram.address.address}:${announcement.port})',
      );
    }

    if (_emitPeerDevice(device, announcement.deviceId)) {
      LogUtil.iTag(
        logTag,
        '[DISCOVER/UDP] ${device.deviceName} (${device.displayAddress})',
      );
    }
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

    await _sendHttpRegister(replyTo.address, scannerHttpPort, payload);
    await _sendUnicast(payload, replyTo);
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
      timeout: const Duration(seconds: 2),
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
    final port = _httpPort;
    if (port == null) {
      return;
    }

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(payload, target, port);
    } catch (e) {
      LogUtil.wTag(
        logTag,
        '单播回复失败 -> ${target.address}:$port: $e',
      );
    } finally {
      socket?.close();
    }
  }

  Future<int> _sendMulticastPacket(List<int> payload) async {
    final port = _httpPort;
    if (port == null) {
      return 0;
    }

    final multicast = InternetAddress(AppConstants.multicastGroup);
    var sentCount = 0;

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      MulticastSocketOptions.setMulticastTtl(
        socket,
        MulticastSocketOptions.defaultMulticastTtl,
      );
      socket.broadcastEnabled = true;

      socket.send(payload, multicast, port);
      sentCount++;

      final interfaces = await NetworkUtil.getLanNetworkInterfaces();
      for (final interface in interfaces) {
        final interfaceIp = NetworkUtil.getPrimaryPrivateIpv4(interface);
        if (interfaceIp == null) {
          continue;
        }

        final broadcast = NetworkUtil.getSubnetBroadcast(interfaceIp);
        if (broadcast != null) {
          socket.send(payload, InternetAddress(broadcast), port);
          sentCount++;
        }
      }

      socket.send(
        payload,
        InternetAddress('255.255.255.255'),
        port,
      );
      sentCount++;
    } catch (e) {
      LogUtil.wTag(logTag, '发送 UDP 发现包失败: $e');
    } finally {
      socket?.close();
    }

    return sentCount;
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

  bool get _supportsReusePort => Platform.isLinux || Platform.isAndroid;
}
