import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/relay_config.dart';

void main() {
  group('RelayConfig URL derivation', () {
    test('maps https to a wss signaling endpoint', () {
      const config = RelayConfig(
        serverUrl: 'https://relay.example.com',
        token: 'token',
      );

      expect(
        config.signalUri.toString(),
        'wss://relay.example.com/v1/signal',
      );
      expect(
        config.streamUri('abc').toString(),
        'https://relay.example.com/v1/stream/abc',
      );
    });

    test('maps http to ws so a local relay can be used for development', () {
      const config = RelayConfig(
        serverUrl: 'http://127.0.0.1:18443',
        token: 'token',
      );

      expect(config.signalUri.toString(), 'ws://127.0.0.1:18443/v1/signal');
      expect(
        config.streamUri('abc').toString(),
        'http://127.0.0.1:18443/v1/stream/abc',
      );
    });

    test('keeps a sub-path so the relay can sit behind a reverse proxy', () {
      const config = RelayConfig(
        serverUrl: 'https://example.com/relay/',
        token: 'token',
      );

      expect(
        config.signalUri.toString(),
        'wss://example.com/relay/v1/signal',
      );
      expect(
        config.streamUri('abc').toString(),
        'https://example.com/relay/v1/stream/abc',
      );
    });

    test('rejects an address without a scheme rather than guessing one', () {
      const config = RelayConfig(
        serverUrl: 'relay.example.com',
        token: 'token',
      );

      expect(config.baseUri, isNull);
      expect(config.signalUri, isNull);
      expect(config.isValid, isFalse);
    });

    test('rejects a scheme that is not http or https', () {
      const config = RelayConfig(
        serverUrl: 'ftp://relay.example.com',
        token: 'token',
      );

      expect(config.baseUri, isNull);
    });

    test('drops a query string that would break the endpoint paths', () {
      const config = RelayConfig(
        serverUrl: 'https://relay.example.com/?debug=1',
        token: 'token',
      );

      expect(config.signalUri.toString(), 'wss://relay.example.com/v1/signal');
    });
  });

  group('RelayConfig activation', () {
    test('needs both an address and a token before it can be used', () {
      expect(
        const RelayConfig(serverUrl: 'https://a.example', enabled: true)
            .isActive,
        isFalse,
      );
      expect(
        const RelayConfig(token: 'token', enabled: true).isActive,
        isFalse,
      );
      expect(
        const RelayConfig(
          serverUrl: 'https://a.example',
          token: 'token',
          enabled: true,
        ).isActive,
        isTrue,
      );
    });

    test('keeps the address and token when switched off', () {
      const config = RelayConfig(
        serverUrl: 'https://a.example',
        token: 'token',
        enabled: true,
      );

      final disabled = config.copyWith(enabled: false);
      expect(disabled.isActive, isFalse);
      expect(disabled.isConfigured, isTrue);
      expect(disabled.serverUrl, config.serverUrl);
      expect(disabled.token, config.token);
    });
  });

  group('RelayConfig serialization', () {
    test('round-trips through JSON', () {
      const config = RelayConfig(
        serverUrl: 'https://relay.example.com',
        token: 'secret-token',
        enabled: true,
      );

      expect(RelayConfig.fromJson(config.toJson()), config);
    });

    test('falls back to empty on a corrupted entry', () {
      expect(
        RelayConfig.fromJson({'serverUrl': 42, 'token': null, 'enabled': 'yes'}),
        RelayConfig.empty,
      );
    });

    test('trims whitespace pasted in with the token', () {
      final config = RelayConfig.fromJson({
        'serverUrl': '  https://relay.example.com  ',
        'token': ' secret ',
        'enabled': true,
      });

      expect(config.serverUrl, 'https://relay.example.com');
      expect(config.token, 'secret');
    });

    test('never puts the token in its string form', () {
      const config = RelayConfig(
        serverUrl: 'https://relay.example.com',
        token: 'super-secret-value',
      );

      expect(config.toString(), isNot(contains('super-secret-value')));
    });
  });
}
