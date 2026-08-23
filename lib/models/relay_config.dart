import '../utils/constants.dart';

/// Connection settings for the user's self-hosted relay server.
///
/// Only one relay is supported (decision D4), but the settings are stored as a
/// single JSON object rather than a handful of loose preference keys so that
/// supporting several later needs no data migration.
class RelayConfig {
  /// Base URL of the relay, for example `https://relay.example.com`.
  final String serverUrl;

  /// Admission token, matching the server's `RELAY_TOKEN`.
  final String token;

  /// Whether the client should connect at all.
  ///
  /// Kept separate from [serverUrl] so a user can switch the relay off without
  /// losing the address and token they typed in.
  final bool enabled;

  const RelayConfig({
    this.serverUrl = '',
    this.token = '',
    this.enabled = false,
  });

  static const RelayConfig empty = RelayConfig();

  /// Whether there is enough here to attempt a connection.
  bool get isConfigured => serverUrl.isNotEmpty && token.isNotEmpty;

  bool get isActive => enabled && isConfigured;

  /// Parsed [serverUrl], or null when it is missing or malformed.
  Uri? get baseUri {
    if (serverUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(serverUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    // A bare `relay.example.com` parses with an empty scheme and would then
    // produce an unusable ws:// URL, so require the user to be explicit.
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    return uri;
  }

  bool get isValid => baseUri != null && token.isNotEmpty;

  /// WebSocket URL of the signaling plane.
  Uri? get signalUri => _endpoint(
    AppConstants.relaySignalPath,
    webSocket: true,
  );

  /// HTTP URL of one data stream.
  Uri? streamUri(String streamId) =>
      _endpoint('${AppConstants.relayStreamPath}/$streamId');

  /// Builds an endpoint URL from the configured base.
  ///
  /// Assembled field by field rather than with `Uri.replace`, which keeps any
  /// query string and fragment the user happened to paste in — those would
  /// end up appended after the endpoint path and break the request.
  Uri? _endpoint(String path, {bool webSocket = false}) {
    final base = baseUri;
    if (base == null) {
      return null;
    }

    final secure = base.scheme == 'https';
    return Uri(
      scheme: webSocket ? (secure ? 'wss' : 'ws') : base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: _joinPath(base.path, path),
    );
  }

  /// Host shown in the UI and in error messages, without the scheme.
  String get displayHost => baseUri?.host ?? serverUrl;

  RelayConfig copyWith({String? serverUrl, String? token, bool? enabled}) {
    return RelayConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      token: token ?? this.token,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'token': token,
    'enabled': enabled,
  };

  /// Reads a stored config, falling back to [empty] on anything unexpected.
  ///
  /// A corrupted entry must not stop the app from starting; the user can
  /// simply re-enter the server details.
  static RelayConfig fromJson(Map<String, dynamic> json) {
    final serverUrl = json['serverUrl'];
    final token = json['token'];
    final enabled = json['enabled'];

    return RelayConfig(
      serverUrl: serverUrl is String ? serverUrl.trim() : '',
      token: token is String ? token.trim() : '',
      enabled: enabled is bool ? enabled : false,
    );
  }

  /// Joins a base path with an endpoint path, tolerating the relay being
  /// mounted under a sub-path by a reverse proxy.
  static String _joinPath(String basePath, String endpoint) {
    final trimmed = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    return '$trimmed$endpoint';
  }

  @override
  bool operator ==(Object other) =>
      other is RelayConfig &&
      other.serverUrl == serverUrl &&
      other.token == token &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(serverUrl, token, enabled);

  /// Deliberately omits the token so it cannot leak into logs.
  @override
  String toString() =>
      'RelayConfig(serverUrl: $serverUrl, enabled: $enabled, '
      'token: ${token.isEmpty ? 'unset' : 'set'})';
}
