import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/utils/transfer_path_util.dart';
import 'package:path/path.dart' as p;

/// The transfer path comes from the other device, so it is joined onto the
/// save directory only after it can no longer point anywhere else.
void main() {
  String? posix(String input) =>
      TransferPathUtil.sanitizeRelativePath(input, windows: false);
  String? windows(String input) =>
      TransferPathUtil.sanitizeRelativePath(input, windows: true);

  group('every platform', () {
    test('keeps ordinary nested paths', () {
      expect(posix('photos/2026/a.jpg'), 'photos/2026/a.jpg');
      expect(windows('photos/2026/a.jpg'), r'photos\2026\a.jpg');
    });

    test('treats leading separators as relative', () {
      expect(posix('/etc/passwd'), 'etc/passwd');
      expect(windows(r'\\server\share\x'), r'server\share\x');
    });

    test('rejects parent traversal and empty input', () {
      expect(posix('../x'), isNull);
      expect(posix(r'a\..\..\x'), isNull);
      expect(windows('a/../../x'), isNull);
      expect(posix('   '), isNull);
      expect(posix('./'), isNull);
    });

    test('rejects control characters', () {
      expect(posix('a\u0000b.txt'), isNull);
      expect(windows('a\nb.txt'), isNull);
    });
  });

  group('windows', () {
    test('a drive letter cannot replace the save directory', () {
      final relative = windows('C:/Windows/evil.dll');

      expect(relative, isNotNull);
      final joined = p.windows.join(r'D:\Downloads', relative);
      expect(p.windows.isWithin(r'D:\Downloads', joined), isTrue);
    });

    test('replaces characters Windows gives meaning to', () {
      expect(windows('file.txt:stream'), 'file.txt_stream');
      expect(windows('a<b>c?.txt'), 'a_b_c_.txt');
    });

    test('drops trailing dots and spaces, rejecting what is left empty', () {
      expect(windows('name. . '), 'name');
      expect(windows('...'), isNull);
    });

    test('escapes reserved device names', () {
      expect(windows('CON'), '_CON');
      expect(windows('dir/nul.txt'), r'dir\_nul.txt');
      expect(windows('console.txt'), 'console.txt');
    });

    test('leaves colons alone elsewhere', () {
      expect(posix('a:b.txt'), 'a:b.txt');
    });
  });
}
