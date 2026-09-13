import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/paired_device.dart';
import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/platform_util.dart';

/// Persistent trust list of paired peers.
///
/// Backed by `paired_devices.json` in the application support directory and
/// cached in memory. Writes are serialized through [_writeQueue] so a pairing
/// completing while the settings page saves an `autoAccept` toggle cannot
/// interleave and truncate the file.
class PairedDeviceStore {
  static final PairedDeviceStore instance = PairedDeviceStore._();

  PairedDeviceStore._() : _overrideFilePath = null;

  PairedDeviceStore.forTesting({String? filePath})
    : _overrideFilePath = filePath;

  final String? _overrideFilePath;
  final String logTag = LogTags.pairing;

  final List<PairedDevice> _devices = [];
  final StreamController<List<PairedDevice>> _changes =
      StreamController<List<PairedDevice>>.broadcast();

  Future<void>? _loading;
  Future<void> _writeQueue = Future.value();

  /// Emits the full list whenever it changes, so the settings page can rebuild.
  Stream<List<PairedDevice>> get changes => _changes.stream;

  Future<List<PairedDevice>> loadAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_devices);
  }

  /// Cached view; empty until [loadAll] has run at least once.
  List<PairedDevice> get cached => List.unmodifiable(_devices);

  Future<PairedDevice?> find(String deviceId) async {
    await _ensureLoaded();
    return _findCached(deviceId);
  }

  Future<bool> isPaired(String deviceId) async => await find(deviceId) != null;

  /// Inserts [device], or updates the existing entry with the same device id.
  ///
  /// A device id is a fingerprint of the public key, so an existing entry with
  /// a different key means someone is impersonating a trusted peer; the update
  /// is refused rather than silently rotating the trusted key.
  Future<bool> upsert(PairedDevice device) async {
    await _ensureLoaded();
    final index = _devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (index >= 0 && _devices[index].publicKey != device.publicKey) {
      LogUtil.wTag(
        logTag,
        '拒绝更新已配对设备 ${device.deviceId}: 公钥与信任记录不一致',
      );
      return false;
    }

    if (index >= 0) {
      _devices[index] = device;
    } else {
      _devices.add(device);
    }
    await _persist();
    return true;
  }

  /// Refreshes the mutable hints of an already trusted peer.
  ///
  /// Does nothing when the peer is not paired, so a stranger cannot create an
  /// entry just by being discovered on the LAN.
  Future<void> touch(
    String deviceId, {
    String? deviceName,
    String? lastSeenLan,
  }) async {
    await _ensureLoaded();
    final index = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (index < 0) {
      return;
    }
    final current = _devices[index];
    final updated = current.copyWith(
      deviceName: (deviceName != null && deviceName.isNotEmpty)
          ? deviceName
          : null,
      lastSeenLan: lastSeenLan,
    );
    if (updated == current) {
      return;
    }
    _devices[index] = updated;
    await _persist();
  }

  /// Drops the LAN hint when the peer was not seen on this scan.
  Future<void> clearLastSeenLan(String deviceId) async {
    await _ensureLoaded();
    final index = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (index < 0) {
      return;
    }
    final current = _devices[index];
    if (current.lastSeenLan == null) {
      return;
    }
    _devices[index] = current.copyWith(clearLastSeenLan: true);
    await _persist();
  }

  Future<void> remove(String deviceId) async {
    await _ensureLoaded();
    final before = _devices.length;
    _devices.removeWhere((d) => d.deviceId == deviceId);
    if (_devices.length == before) {
      return;
    }
    await _persist();
  }

  Future<void> clear() async {
    await _ensureLoaded();
    if (_devices.isEmpty) {
      return;
    }
    _devices.clear();
    await _persist();
  }

  PairedDevice? _findCached(String deviceId) {
    for (final device in _devices) {
      if (device.deviceId == deviceId) {
        return device;
      }
    }
    return null;
  }

  Future<void> _ensureLoaded() {
    return _loading ??= _load().catchError((Object error) {
      _loading = null;
      throw error;
    });
  }

  Future<void> _load() async {
    try {
      final file = File(await _resolvePath());
      if (!await file.exists()) {
        return;
      }
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) {
        LogUtil.wTag(logTag, '配对列表格式异常，忽略');
        return;
      }
      for (final entry in raw) {
        final device = PairedDevice.tryParse(entry);
        if (device != null) {
          _devices.add(device);
        }
      }
      LogUtil.iTag(logTag, '加载配对设备 ${_devices.length} 台');
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '加载配对列表失败: $e', e, stackTrace);
    }
  }

  Future<void> _persist() {
    final snapshot = List<PairedDevice>.from(_devices);
    _writeQueue = _writeQueue.then((_) => _write(snapshot));
    _changes.add(List.unmodifiable(snapshot));
    return _writeQueue;
  }

  Future<void> _write(List<PairedDevice> devices) async {
    try {
      final file = File(await _resolvePath());
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(devices.map((d) => d.toJson()).toList()),
        flush: true,
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '保存配对列表失败: $e', e, stackTrace);
    }
  }

  Future<String> _resolvePath() async {
    return _overrideFilePath ??
        await PlatformUtil.getAppSupportFilePath(
          AppConstants.pairedDevicesFileName,
        );
  }
}
