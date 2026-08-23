import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/identity_service.dart';
import 'package:icy_easy_send/services/pairing_handler.dart';
import 'package:shelf/shelf.dart';

/// Covers the paths a peer can reach without a user interface, which is
/// exactly where an attacker would aim: everything else requires a human to
/// compare digits on screen.
void main() {
  final validKey = base64Encode(List<int>.filled(32, 3));

  Request post(String path, Object? body) {
    return Request(
      'POST',
      Uri.parse('http://localhost:9527$path'),
      body: body is String ? body : jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> jsonOf(Response response) async {
    return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  }

  group('POST /pair/request', () {
    test('rejects a body that is not a JSON object', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', '"just a string"'),
      );

      expect(response.statusCode, 400);
      expect((await jsonOf(response))['reason'], 'bad_request');
    });

    test('rejects malformed JSON', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', 'not json'),
      );

      expect(response.statusCode, 500);
      expect((await jsonOf(response))['accepted'], isFalse);
    });

    test('rejects a request without a device id or public key', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', {'deviceName': 'Laptop'}),
      );

      expect(response.statusCode, 400);
      expect((await jsonOf(response))['reason'], 'bad_request');
    });

    test('rejects a device id that is not the fingerprint of the key',
        () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', {
          'deviceId': '0' * 32,
          'publicKey': validKey,
          'deviceName': 'Impostor',
        }),
      );

      expect((await jsonOf(response))['reason'], 'identity_mismatch');
    });

    test('rejects a public key of the wrong length', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', {
          'deviceId': '0' * 32,
          'publicKey': base64Encode(List<int>.filled(16, 3)),
        }),
      );

      expect((await jsonOf(response))['reason'], 'identity_mismatch');
    });

    test('refuses to pair when no interface can show the code', () async {
      final key = List<int>.filled(32, 3);
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairRequest(
        post('/pair/request', {
          'deviceId': await IdentityService.deviceIdFromPublicKey(key),
          'publicKey': validKey,
          'deviceName': 'Laptop',
        }),
      );

      final body = await jsonOf(response);
      expect(body['reason'], 'no_ui');
      expect(body['accepted'], isFalse);
    });

    test('refuses while the app is in the background', () async {
      final key = List<int>.filled(32, 3);
      final handler = PairingHandler(
        contextGetter: () => null,
        isInBackgroundGetter: () => true,
      );

      final response = await handler.handlePairRequest(
        post('/pair/request', {
          'deviceId': await IdentityService.deviceIdFromPublicKey(key),
          'publicKey': validKey,
        }),
      );

      expect((await jsonOf(response))['reason'], 'no_ui');
    });
  });

  group('POST /pair/confirm', () {
    test('rejects a body that is not a JSON object', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairConfirm(
        post('/pair/confirm', '42'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects a confirm without a device id', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairConfirm(
        post('/pair/confirm', {'accepted': true}),
      );

      expect(response.statusCode, 400);
    });

    test('cannot commit a pairing that was never approved here', () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairConfirm(
        post('/pair/confirm', {'deviceId': 'peer-1', 'accepted': true}),
      );

      expect(response.statusCode, 409);
      expect((await jsonOf(response))['reason'], 'unknown_pairing');
    });

    test('a cancelled pairing is acknowledged without trusting anyone',
        () async {
      final handler = PairingHandler(contextGetter: () => null);

      final response = await handler.handlePairConfirm(
        post('/pair/confirm', {'deviceId': 'peer-1', 'accepted': false}),
      );

      expect(response.statusCode, 200);
      final body = await jsonOf(response);
      expect(body['ok'], isTrue);
      expect(body['paired'], isFalse);
    });
  });
}
