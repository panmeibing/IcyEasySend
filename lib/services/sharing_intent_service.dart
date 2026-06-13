import 'dart:async';
import 'dart:io';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

import '../utils/log_util.dart';
import 'cache_cleanup_service.dart';

/// Service to handle receiving shared files from other apps
class SharingIntentService {
  static final String logTag = LogTags.system;

  static List<SharedFile>? _earlyCapturedSharing;
  static bool _earlyCaptureDone = false;

  StreamSubscription? _intentStreamSubscription;
  final List<File> _sharedFiles = [];
  final StreamController<List<File>> _sharedFilesController =
      StreamController<List<File>>.broadcast();

  bool _initialSharingLoaded = false;
  Future<void>? _initialSharingFuture;

  /// Stream of shared files while the app is already running
  Stream<List<File>> get sharedFilesStream => _sharedFilesController.stream;

  /// Get current buffered shared files
  List<File> get sharedFiles => List.unmodifiable(_sharedFiles);

  /// Capture the cold-start share payload before startup cache cleanup runs.
  ///
  /// On Android, [flutter_sharing_intent] copies shared media into the app
  /// cache directory. If cache cleanup deletes those files first, the share
  /// payload becomes unusable.
  static Future<Set<String>> captureInitialSharingEarly() async {
    if (_earlyCaptureDone) {
      return _extractPaths(_earlyCapturedSharing);
    }
    _earlyCaptureDone = true;

    if (!Platform.isAndroid && !Platform.isIOS) {
      return {};
    }

    try {
      _earlyCapturedSharing =
          await FlutterSharingIntent.instance.getInitialSharing();
      final paths = _extractPaths(_earlyCapturedSharing);
      LogUtil.iTag(logTag, '启动前捕获分享: ${paths.length} 个文件');
      for (final path in paths) {
        LogUtil.dTag(logTag, '分享文件路径: $path');
      }
      return paths;
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '启动前捕获分享失败: $e', e, stackTrace);
      return {};
    }
  }

  static Set<String> _extractPaths(List<SharedFile>? files) {
    if (files == null) {
      return {};
    }
    return files.map((file) => file.value).whereType<String>().toSet();
  }

  /// Start listening for shares while the app is in memory
  void initialize() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    if (_intentStreamSubscription != null) {
      return;
    }

    _intentStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen(
          (files) => _handleSharedMedia(files, notifyListeners: true),
          onError: (err) {
            LogUtil.wTag(logTag, '分享流监听错误: $err');
          },
        );
  }

  /// Load the share payload that opened the app from cold start.
  ///
  /// This must be consumed by the UI after it is ready, because broadcast
  /// streams do not replay events to late subscribers.
  Future<void> loadInitialSharingIfNeeded() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    _initialSharingFuture ??= _loadInitialSharing();
    await _initialSharingFuture;
  }

  Future<void> _loadInitialSharing() async {
    if (_initialSharingLoaded) {
      return;
    }
    _initialSharingLoaded = true;

    if (_earlyCapturedSharing != null) {
      LogUtil.iTag(
        logTag,
        '使用启动前捕获的分享: ${_earlyCapturedSharing!.length} 个条目',
      );
      _handleSharedMedia(_earlyCapturedSharing!, notifyListeners: false);
      return;
    }

    try {
      final value = await FlutterSharingIntent.instance.getInitialSharing();
      LogUtil.iTag(logTag, '读取初始分享: ${value.length} 个条目');
      _handleSharedMedia(value, notifyListeners: false);
    } catch (e, stackTrace) {
      LogUtil.wTag(logTag, '读取初始分享失败: $e', e, stackTrace);
    }
  }

  /// Returns buffered shared files without clearing them.
  List<File> takePendingSharedFiles() {
    if (_sharedFiles.isEmpty) {
      return [];
    }
    return List<File>.from(_sharedFiles);
  }

  void _handleSharedMedia(
    List<SharedFile> sharedMediaFiles, {
    required bool notifyListeners,
  }) {
    if (sharedMediaFiles.isEmpty) {
      return;
    }

    _sharedFiles.clear();

    for (final media in sharedMediaFiles) {
      if (media.value != null) {
        final file = File(media.value!);
        if (file.existsSync()) {
          _sharedFiles.add(file);
        } else {
          LogUtil.wTag(logTag, '分享文件不存在: ${media.value}');
        }
      }
    }

    if (_sharedFiles.isEmpty) {
      return;
    }

    LogUtil.iTag(
      logTag,
      '缓冲分享文件 ${_sharedFiles.length} 个 '
      '(notifyListeners=$notifyListeners)',
    );

    if (notifyListeners) {
      _sharedFilesController.add(List<File>.from(_sharedFiles));
    }
  }

  /// Clear shared files from memory and reset the plugin state.
  void clearSharedFiles() {
    _sharedFiles.clear();
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterSharingIntent.instance.reset();
    }
  }

  /// Delete on-disk cache copies created by the share intent plugin.
  Future<void> cleanupSharedCacheFiles(Iterable<File> files) async {
    final cacheCleanup = CacheCleanupService();
    await cacheCleanup.deleteCacheFilesIfPresent(files.map((file) => file.path));
  }

  /// Dispose the service
  void dispose() {
    _intentStreamSubscription?.cancel();
    _sharedFilesController.close();
  }
}
