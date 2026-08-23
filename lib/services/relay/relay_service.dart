import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/paired_device.dart';
import '../../models/relay_config.dart';
import '../../transport/relay_channel.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../paired_device_store.dart';
import '../preferences_service.dart';
import 'relay_client.dart';
import 'relay_clipboard_service.dart';
import 'relay_pairing_service.dart';
import 'relay_receive_coordinator.dart';

/// Owns everything relay-related for the lifetime of the app.
///
/// One connection serves both directions, so neither the sending channel nor
/// the receive coordinator may own it: this holds the [RelayClient] and hands
/// it to both. `HTTPServerManager` starts and stops this alongside the LAN
/// server, and supplies the same UI accessors the LAN handlers use.
class RelayService {
  static final RelayService instance = RelayService._();

  RelayService._()
    : _preferencesService = PreferencesService(),
      _pairedDevices = PairedDeviceStore.instance,
      client = RelayClient();

  /// Test seam, letting a test drive a service without touching the singleton.
  RelayService.forTesting({
    required this.client,
    PreferencesService? preferencesService,
    PairedDeviceStore? pairedDevices,
    RelayChannel? channel,
    RelayReceiveCoordinator? coordinator,
    RelayPairingService? pairing,
  }) : _preferencesService = preferencesService ?? PreferencesService(),
       _pairedDevices = pairedDevices ?? PairedDeviceStore.instance,
       _channel = channel,
       _coordinator = coordinator,
       _pairing = pairing;

  final RelayClient client;
  final PreferencesService _preferencesService;
  final PairedDeviceStore _pairedDevices;

  final String logTag = LogTags.transfer;

  RelayChannel? _channel;
  RelayReceiveCoordinator? _coordinator;
  RelayPairingService? _pairing;
  RelayClipboardService? _clipboard;
  StreamSubscription<List<PairedDevice>>? _pairedSubscription;
  bool _started = false;

  BuildContext? Function()? _contextGetter;
  bool Function()? _isInBackgroundGetter;
  VoidCallback? Function()? _historyRefreshCallbackGetter;
  VoidCallback? _onPaired;

  /// Pairing over the relay, available to the settings page for outbound
  /// requests and running on its own for inbound ones.
  RelayPairingService get pairing => _pairing ??= _createPairingService();

  /// Clipboard sync over the relay (small payloads on the signaling plane).
  RelayClipboardService get clipboard =>
      _clipboard ??= _createClipboardService();

  /// The outbound channel. Created on demand so that constructing it never
  /// depends on the relay being configured or connected.
  RelayChannel get channel => _channel ??= RelayChannel(client: client);

  RelayConfig get config => client.config;

  RelayConnectionState get state => client.state;

  Stream<RelayConnectionState> get stateChanges => client.stateChanges;

  /// Supplies the accessors the receive side needs to raise a dialog.
  ///
  /// Called before [start] by whoever owns the app's UI lifecycle.
  void bindUi({
    BuildContext? Function()? contextGetter,
    bool Function()? isInBackgroundGetter,
    VoidCallback? Function()? historyRefreshCallbackGetter,
    VoidCallback? onPaired,
  }) {
    _contextGetter = contextGetter;
    _isInBackgroundGetter = isInBackgroundGetter;
    _historyRefreshCallbackGetter = historyRefreshCallbackGetter;
    _onPaired = onPaired;
  }

  /// Loads the stored settings and connects if the relay is switched on.
  ///
  /// Never throws: a broken relay must not stop the LAN half of the app from
  /// starting.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    try {
      _coordinator ??= RelayReceiveCoordinator(
        client: client,
        contextGetter: () => _contextGetter?.call(),
        isInBackgroundGetter: () => _isInBackgroundGetter?.call() ?? false,
        historyRefreshCallbackGetter: () =>
            _historyRefreshCallbackGetter?.call(),
      );
      _coordinator!.start();
      pairing.start();
      clipboard.start();

      // Presence is only reported for peers this device asks about, and the
      // only peers worth asking about are the ones it can actually transfer
      // with.
      _pairedSubscription ??= _pairedDevices.changes.listen((devices) {
        unawaited(_syncSubscriptions(devices));
      });

      final config = await _preferencesService.getRelayConfig();
      await client.applyConfig(config);
      await _syncSubscriptions(await _pairedDevices.loadAll());

      if (config.isActive) {
        LogUtil.iTag(logTag, '中转已启用: ${config.displayHost}');
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '中转服务启动失败: $e', e, stackTrace);
    }
  }

  Future<void> stop() async {
    _started = false;
    await _pairedSubscription?.cancel();
    _pairedSubscription = null;
    await _pairing?.stop();
    await _clipboard?.stop();
    await _coordinator?.stop();
    await client.disconnect();
  }

  /// The pairing service outlives any single [bindUi] call — the settings page
  /// can reach it before the app has a navigator — so it is given accessors
  /// that read the current bindings rather than whatever was bound when it was
  /// created.
  RelayPairingService _createPairingService() {
    return RelayPairingService(
      client: client,
      contextGetter: () => _contextGetter?.call(),
      isInBackgroundGetter: () => _isInBackgroundGetter?.call() ?? false,
      onPaired: () => _onPaired?.call(),
    );
  }

  RelayClipboardService _createClipboardService() {
    return RelayClipboardService(
      client: client,
      contextGetter: () => _contextGetter?.call(),
      isInBackgroundGetter: () => _isInBackgroundGetter?.call() ?? false,
    );
  }

  Future<void> dispose() async {
    await stop();
    await client.dispose();
  }

  /// Persists new settings and applies them to the live connection.
  Future<bool> updateConfig(RelayConfig config) async {
    final saved = await _preferencesService.saveRelayConfig(config);
    if (!saved) {
      LogUtil.wTag(logTag, '保存中转设置失败');
      return false;
    }

    await client.applyConfig(config);
    if (config.isActive) {
      await _syncSubscriptions(await _pairedDevices.loadAll());
    }
    return true;
  }

  /// Tries [config] without disturbing the current connection.
  ///
  /// The settings page needs to tell a typo apart from a server that is down
  /// before the user saves, so this runs a throwaway client rather than
  /// applying the settings and watching what happens.
  Future<OperationResult<void>> testConnection(RelayConfig config) async {
    if (!config.isValid) {
      return OperationResult.failure('请填写完整的中转服务器地址和接入令牌');
    }

    final probe = RelayClient();
    try {
      await probe.applyConfig(config.copyWith(enabled: true));
      if (await probe.connect()) {
        return OperationResult.success();
      }
      return OperationResult.failure(
        probe.state == RelayConnectionState.rejected
            ? '中转服务器拒绝了接入令牌或设备身份'
            : '无法连接中转服务器，请检查地址与网络',
      );
    } catch (e) {
      return OperationResult.failure('连接中转服务器失败: $e');
    } finally {
      await probe.dispose();
    }
  }

  Future<void> _syncSubscriptions(List<PairedDevice> devices) async {
    await client.setSubscriptions(devices.map((device) => device.deviceId));
  }
}
