import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/services/clipboard_handler.dart';
import 'package:icy_easy_send/services/language_service.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/services/secret_key_verifier.dart';
import 'package:icy_easy_send/utils/peer_error.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';

/// A receiving device reports failures as codes; the sender words them in
/// its own language.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage('system');
  });

  test('codes are unique and round-trip', () {
    final codes = PeerError.values.map((e) => e.code).toSet();
    expect(codes, hasLength(PeerError.values.length));
    for (final error in PeerError.values) {
      expect(PeerError.fromCode(error.toJson()['code']), error);
    }
    expect(PeerError.fromCode('from_a_future_version'), isNull);
  });

  test('the sender words a code in its own language', () async {
    final body = {'accepted': false, ...PeerError.diskFull.toJson()};

    await LanguageService.instance.setLanguage('ja');
    expect(
      PeerError.describeBody(body, 'fallback'),
      lookupAppLocalizations(const Locale('ja')).peerErrorDiskFull,
    );

    await LanguageService.instance.setLanguage('de');
    expect(
      PeerError.describeBody(body, 'fallback'),
      lookupAppLocalizations(const Locale('de')).peerErrorDiskFull,
    );
  });

  test('an older peer without codes still gets its message shown', () {
    expect(
      PeerError.describeBody({'accepted': false, 'message': '用户拒绝接收文件'}, 'x'),
      '用户拒绝接收文件',
    );
    expect(
      PeerError.describeBody({
        'code': 'from_a_future_version',
        'message': 'Something new',
      }, 'x'),
      'Something new',
    );
    expect(PeerError.describeBody({'accepted': false}, 'fallback'), 'fallback');
    expect(PeerError.describeBody('not a map', 'fallback'), 'fallback');
  });

  test('clipboard size figures make it into the text', () async {
    await LanguageService.instance.setLanguage('en');
    final text = PeerError.describeBody({
      ...PeerError.clipboardTooLarge.toJson(),
      'actualSizeMB': 12.5,
      'maxSizeMB': 10,
    }, 'fallback');
    expect(text, contains('12.50'));
    expect(text, contains('10'));
    expect(
      PeerError.clipboardTooLarge.describe(),
      lookupAppLocalizations(const Locale('en')).peerErrorClipboardTooLarge,
    );
  });

  test('relay file.done carries the code alongside the legacy text', () {
    const done = FileDone(
      sessionId: 's',
      fileId: 'f',
      ok: false,
      bytes: 0,
      code: 'disk_full',
      error: '存储空间不足',
    );
    final parsed = FileDone.tryParse(done.toJson())!;
    expect(parsed.code, 'disk_full');
    expect(parsed.error, '存储空间不足');

    final legacy = FileDone.tryParse({
      'sid': 's',
      'fileId': 'f',
      'ok': false,
      'error': 'old',
    })!;
    expect(legacy.code, isNull);
  });

  test('the clipboard endpoint answers with a code, not prose', () async {
    final handler = ClipboardHandler(
      isInBackgroundGetter: () => true,
      secretKeyVerifier: _RejectingVerifier(),
    );
    final response = await handler.handleClipboardRequest(
      Request(
        'POST',
        Uri.parse('http://localhost/clipboard-request'),
        body: jsonEncode({'requesterDeviceName': 'Phone'}),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(body['accepted'], isFalse);
    expect(body['code'], PeerError.backgroundNeedsSecretKey.code);
    expect(body['message'], PeerError.backgroundNeedsSecretKey.englishMessage);
  });
}

class _RejectingVerifier implements SecretKeyVerifier {
  @override
  Future<bool> verify(
    String? presented, {
    required String? remoteAddress,
  }) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
