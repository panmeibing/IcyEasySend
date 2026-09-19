import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/utils/format_util.dart';
import 'package:icy_easy_send/utils/transfer_rate_tracker.dart';

void main() {
  group('FormatUtil.formatDuration', () {
    test('formats as zero-padded HH:MM:SS', () {
      expect(FormatUtil.formatDuration(const Duration(seconds: 25)), '00:00:25');
      expect(
        FormatUtil.formatDuration(const Duration(minutes: 2, seconds: 5)),
        '00:02:05',
      );
      expect(
        FormatUtil.formatDuration(const Duration(hours: 1, minutes: 15)),
        '01:15:00',
      );
      expect(
        FormatUtil.formatDuration(const Duration(hours: 26, minutes: 3, seconds: 9)),
        '26:03:09',
      );
    });

    test('clamps negative durations to zero', () {
      expect(FormatUtil.formatDuration(const Duration(seconds: -3)), '00:00:00');
    });
  });

  group('FormatUtil transfer labels', () {
    test('builds speed and remaining-time lines', () {
      expect(
        FormatUtil.formatTransferSpeedLabel('Transfer Speed', 1536),
        'Transfer Speed: 1.5 KB/s',
      );
      expect(
        FormatUtil.formatRemainingTimeLabel(
          'Remaining Time',
          const Duration(hours: 0, minutes: 25, seconds: 23),
        ),
        'Remaining Time: 00:25:23',
      );
    });
  });

  group('TransferRateTracker', () {
    test('does not report speed until a full sample window elapses', () {
      final tracker = TransferRateTracker();
      final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);

      expect(
        tracker.onProgress(
          bytesTransferred: 0,
          totalBytes: 10 * 1024 * 1024,
          now: t0,
        ),
        isFalse,
      );
      expect(tracker.speed, 0);

      expect(
        tracker.onProgress(
          bytesTransferred: 512 * 1024,
          totalBytes: 10 * 1024 * 1024,
          now: t0.add(const Duration(milliseconds: 500)),
        ),
        isFalse,
      );
      expect(tracker.speed, 0);
    });

    test('computes speed from the last ~1s byte delta', () {
      final tracker = TransferRateTracker();
      final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);
      const total = 10 * 1024 * 1024;

      tracker.onProgress(bytesTransferred: 0, totalBytes: total, now: t0);
      final changed = tracker.onProgress(
        bytesTransferred: 2 * 1024 * 1024,
        totalBytes: total,
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(changed, isTrue);
      expect(tracker.speed, closeTo(2 * 1024 * 1024, 1));
      expect(tracker.estimatedTimeRemaining, isNotNull);
      // 8 MiB left at 2 MiB/s => 4s
      expect(tracker.estimatedTimeRemaining!.inSeconds, 4);
    });

    test('uses the latest window, not lifetime average', () {
      final tracker = TransferRateTracker();
      final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);
      const total = 20 * 1024 * 1024;

      tracker.onProgress(bytesTransferred: 0, totalBytes: total, now: t0);
      // Slow first second: 1 MiB
      tracker.onProgress(
        bytesTransferred: 1 * 1024 * 1024,
        totalBytes: total,
        now: t0.add(const Duration(seconds: 1)),
      );
      // Fast second second: +5 MiB
      tracker.onProgress(
        bytesTransferred: 6 * 1024 * 1024,
        totalBytes: total,
        now: t0.add(const Duration(seconds: 2)),
      );

      expect(tracker.speed, closeTo(5 * 1024 * 1024, 1));
    });
  });
}
