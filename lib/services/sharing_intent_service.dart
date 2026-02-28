import 'dart:async';
import 'dart:io';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

/// Service to handle receiving shared files from other apps
class SharingIntentService {
  StreamSubscription? _intentStreamSubscription;
  final List<File> _sharedFiles = [];
  final StreamController<List<File>> _sharedFilesController =
      StreamController<List<File>>.broadcast();

  /// Stream of shared files
  Stream<List<File>> get sharedFilesStream => _sharedFilesController.stream;

  /// Get current shared files
  List<File> get sharedFiles => List.unmodifiable(_sharedFiles);

  /// Initialize the service and listen for shared files
  void initialize() {
    // Only initialize on mobile platforms (Android and iOS)
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    // Listen for shared files while app is in memory
    _intentStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen(
          _handleSharedMedia,
          onError: (err) {
            // Handle error silently
          },
        );

    // Get the initial shared files when app is opened from share
    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((value) {
          _handleSharedMedia(value);
        })
        .catchError((error) {
          // Handle error silently
        });
  }

  /// Handle received shared media
  void _handleSharedMedia(List<SharedFile> sharedMediaFiles) {
    if (sharedMediaFiles.isEmpty) return;

    _sharedFiles.clear();

    for (final media in sharedMediaFiles) {
      if (media.value != null) {
        final file = File(media.value!);
        if (file.existsSync()) {
          _sharedFiles.add(file);
        }
      }
    }

    if (_sharedFiles.isNotEmpty) {
      // Create a copy of the list to avoid it being cleared
      final filesCopy = List<File>.from(_sharedFiles);
      _sharedFilesController.add(filesCopy);
    }
  }

  /// Clear shared files
  void clearSharedFiles() {
    _sharedFiles.clear();
    // Only reset on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterSharingIntent.instance.reset();
    }
  }

  /// Dispose the service
  void dispose() {
    _intentStreamSubscription?.cancel();
    _sharedFilesController.close();
  }
}
