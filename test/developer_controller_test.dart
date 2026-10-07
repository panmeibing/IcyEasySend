import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/pages/settings/controllers/developer_controller.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  late Directory dir;
  final controller = DeveloperController();

  setUp(() => dir = Directory.systemTemp.createTempSync('dev_log_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a missing log file is reported as not found', () async {
    final result = await controller.copyLogContent('${dir.path}/none.log');
    expect(result.failure, LogCopyFailure.notFound);
  });

  test('an empty log file is reported as empty', () async {
    final file = File('${dir.path}/app.log')..writeAsStringSync('');
    final result = await controller.copyLogContent(file.path);
    expect(result.failure, LogCopyFailure.empty);
  });

  test('only the last lines are copied', () async {
    final total = AppConstants.maxReadLogLines + 5;
    final file = File('${dir.path}/app.log')
      ..writeAsStringSync(
        '${List.generate(total, (i) => 'line $i').join('\n')}\n',
      );

    final result = await controller.copyLogContent(file.path);

    expect(result.failure, isNull);
    expect(result.lineCount, AppConstants.maxReadLogLines);
    expect(result.content!.split('\n').last, 'line ${total - 1}');
  });
}
