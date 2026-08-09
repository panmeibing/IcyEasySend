import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/utils/web_share_http_util.dart';

void main() {
  test('isValidToken accepts 32-char hex only', () {
    expect(
      WebShareHttpUtil.isValidToken('d45c597713b96c71ebeb132337680f7a'),
      isTrue,
    );
    expect(WebShareHttpUtil.isValidToken('abc'), isFalse);
    expect(WebShareHttpUtil.isValidToken('../x'), isFalse);
    expect(WebShareHttpUtil.isValidToken(''), isFalse);
  });

  test('isValidFileId rejects path-like values', () {
    expect(WebShareHttpUtil.isValidFileId('0333287e02'), isTrue);
    expect(WebShareHttpUtil.isValidFileId('../secret'), isFalse);
    expect(WebShareHttpUtil.isValidFileId('a/b'), isFalse);
    expect(WebShareHttpUtil.isValidFileId(''), isFalse);
  });

  test('asciiFallbackFileName for Chinese becomes download.ext', () {
    expect(
      WebShareHttpUtil.asciiFallbackFileName('计算机软件著作权登记申请表.pdf'),
      'download.pdf',
    );
    expect(
      WebShareHttpUtil.asciiFallbackFileName('report-v2.final.zip'),
      'report-v2.final.zip',
    );
  });
}
