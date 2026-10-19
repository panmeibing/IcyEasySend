import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/transfer/batch_progress.dart';

void main() {
  test('sums what each file has sent against the batch total', () {
    final progress = BatchProgress({0: 100, 1: 300});
    progress.update(0, 50);
    progress.update(1, 150);

    expect(progress.sentBytes, 200);
    expect(progress.totalBytes, 400);
    expect(progress.fraction, 0.5);
  });

  test('a file that fails part-way takes only its unsent bytes out', () {
    final progress = BatchProgress({0: 100, 1: 300});
    progress.update(1, 120);
    progress.settle(1, success: false);
    progress.update(0, 100);
    progress.settle(0, success: true);

    // 100 + 120 sent of a total that shrank by 180.
    expect(progress.totalBytes, 220);
    expect(progress.sentBytes, 220);
    expect(progress.fraction, 1.0);
  });

  test('a file cancelled before it started leaves the total entirely', () {
    final progress = BatchProgress({0: 100, 1: 300});
    progress.settle(1, success: false);
    progress.update(0, 50);

    expect(progress.totalBytes, 100);
    expect(progress.fraction, 0.5);
  });

  test('the byte count never goes backwards when a file drops out', () {
    final progress = BatchProgress({0: 100});
    progress.update(0, 60);
    final before = progress.sentBytes;
    progress.settle(0, success: false);

    expect(progress.sentBytes, greaterThanOrEqualTo(before));
  });

  test('progress arriving after a file settled is ignored', () {
    final progress = BatchProgress({0: 100, 1: 100});
    progress.update(0, 30);
    progress.settle(0, success: false);
    progress.update(0, 90);

    expect(progress.sentBytes, 30);
  });

  test('success counts the whole file even without a final tick', () {
    final progress = BatchProgress({0: 100});
    progress.update(0, 99);
    progress.settle(0, success: true);

    expect(progress.sentBytes, 100);
    expect(progress.fraction, 1.0);
  });
}
