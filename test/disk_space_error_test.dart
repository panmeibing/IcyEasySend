import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/utils/disk_space_error.dart';
import 'package:icy_easy_send/utils/operation_result.dart';

/// Telling "the disk is full" apart from every other reason a write can fail.
///
/// The receive path has no free-space pre-flight check — the plugin that
/// reports remaining space is unreliable — so this classifier is the only
/// thing that turns a full disk into something the user can act on. Getting it
/// wrong in either direction is bad: a miss buries the cause in a generic
/// save error, and a false positive tells the user to free up space when the
/// real problem was permissions.
void main() {
  FileSystemException failure(String message, [int? code]) {
    return FileSystemException(
      'write failed',
      '/tmp/incoming.bin',
      code == null ? null : OSError(message, code),
    );
  }

  group('error codes', () {
    test('recognises this platform\'s disk-full code', () {
      // ENOSPC everywhere except Windows, which uses its own Win32 table.
      final code = Platform.isWindows ? 112 : 28;

      expect(DiskSpaceError.isDiskFull(failure('disk full', code)), isTrue);
    });

    test('recognises both Win32 disk-full codes', () {
      if (!Platform.isWindows) {
        return;
      }

      // ERROR_HANDLE_DISK_FULL and ERROR_DISK_FULL.
      expect(DiskSpaceError.isDiskFull(failure('full', 39)), isTrue);
      expect(DiskSpaceError.isDiskFull(failure('full', 112)), isTrue);
    });

    test('does not accept another platform\'s code', () {
      // 28 means something unrelated on Windows, and 112 does off it.
      final foreign = Platform.isWindows ? 28 : 112;

      expect(DiskSpaceError.isDiskFull(failure('some error', foreign)), isFalse);
    });

    test('does not mistake a permission failure for a full disk', () {
      final code = Platform.isWindows ? 5 : 13;

      expect(
        DiskSpaceError.isDiskFull(failure('Permission denied', code)),
        isFalse,
      );
    });
  });

  group('message fallback', () {
    test('matches the common wordings when no code came through', () {
      const wordings = [
        'No space left on device',
        'There is not enough space on the disk',
        'The disk is full',
      ];

      for (final wording in wordings) {
        expect(
          DiskSpaceError.isDiskFull(FileSystemException(wording)),
          isTrue,
          reason: wording,
        );
      }
    });

    test('leaves unrelated messages alone', () {
      expect(
        DiskSpaceError.isDiskFull(
          const FileSystemException('Cannot open file', '/tmp/x'),
        ),
        isFalse,
      );
    });
  });

  test('ignores anything that is not a filesystem failure', () {
    expect(DiskSpaceError.isDiskFull(StateError('closed')), isFalse);
    expect(DiskSpaceError.isDiskFull('No space left on device'), isFalse);
    expect(DiskSpaceError.isDiskFull(null), isFalse);
  });

  group('result metadata', () {
    test('a failure tagged with the metadata reads back as disk full', () {
      final result = OperationResult<void>.failure(
        '存储空间不足',
        metadata: DiskSpaceError.metadata,
      );

      expect(result.isFailure, isTrue);
      expect(result.isDiskFull, isTrue);
    });

    test('every other result does not', () {
      expect(OperationResult<void>.failure('timed out').isDiskFull, isFalse);
      expect(OperationResult<void>.success().isDiskFull, isFalse);
    });
  });
}
