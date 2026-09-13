import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../models/relay_config.dart';
import '../../utils/constants.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../identity_service.dart';
import 'relay_crypto.dart';
import 'relay_protocol.dart';

/// How the client currently stands with the relay server.
enum RelayConnectionState {
  /// Not connected and not trying, either because no relay is configured or
  /// because the user switched it off.
  disabled,

  /// Trying to establish or re-establish the connection.
  connecting,

  /// Authenticated and ready to carry traffic.
  connected,

  /// The connection dropped and a retry is scheduled.
  reconnecting,

  /// The server refused this client. Retrying would be pointless and would
  /// only hammer somebody's VPS, so the client stops until settings change.
  rejected,
}

/// An application message forwarded from a peer.
class RelayInboundPayload {
  final String fromDeviceId;
  final Map<String, dynamic> payload;

  const RelayInboundPayload({
    required this.fromDeviceId,
    required this.payload,
  });

  String get type => payload['type'] as String;
}

/// A peer coming online or going offline on the relay.
class RelayPresenceEvent {
  final String deviceId;
  final bool online;

  const RelayPresenceEvent({required this.deviceId, required this.online});
}

/// A server error that answers a message this client sent.
class RelayErrorEvent {
  final String? mid;
  final String code;
  final String? message;

  const RelayErrorEvent({required this.code, this.mid, this.message});
}

/// Opens a WebSocket. Injectable so tests can supply their own transport.
typedef RelaySocketConnector =
    Future<WebSocket> Function(Uri uri, Map<String, dynamic> headers);

/// The client's long-lived connection to the relay's signaling plane.
///
/// It owns the admission handshake, presence bookkeeping and message routing.
/// It knows nothing about files: [RelayChannel] and the receive coordinator
/// build the transfer protocol on top of [sendPayload] and [payloads].
///
/// Encrypted messages are opened here, before anyone else sees them, so the
/// rest of the app only ever deals in plaintext and cannot accidentally act on
/// a message that failed to authenticate.
class RelayClient {
  final IdentityService _identity;
  final RelaySocketConnector _connector;
  final String logTag = LogTags.transfer;

  /// Sessions whose keys this client can decrypt with.
  ///
  /// Owned here rather than by the sending and receiving halves because one
  /// socket carries both, and an inbound message names only its session id.
  final RelaySessionRegistry sessions = RelaySessionRegistry();

  /// Serializes payload delivery.
  ///
  /// Decryption is asynchronous, so without this a plaintext message could
  /// overtake an encrypted one that arrived before it and the receiver would
  /// see a file announced before the manifest that describes it.
  Future<void> _delivery = Future<void>.value();

  RelayConfig _config = RelayConfig.empty;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  RelayConnectionState _state = RelayConnectionState.disabled;
  Completer<bool>? _handshake;

  final Map<String, Completer<RelayEnvelope>> _pendingRequests = {};
  final Set<String> _subscriptions = {};
  final Set<String> _onlinePeers = {};
  int _messageCounter = 0;

  final StreamController<RelayConnectionState> _stateController =
      StreamController<RelayConnectionState>.broadcast();
  final StreamController<RelayInboundPayload> _payloadController =
      StreamController<RelayInboundPayload>.broadcast();
  final StreamController<RelayPresenceEvent> _presenceController =
      StreamController<RelayPresenceEvent>.broadcast();
  final StreamController<RelayErrorEvent> _errorController =
      StreamController<RelayErrorEvent>.broadcast();

  bool _disposed = false;

  /// How long the admission handshake may take before the attempt is written
  /// off. Overridable so tests do not have to wait out the real timeout.
  final Duration _handshakeTimeout;

  RelayClient({
    IdentityService? identity,
    RelaySocketConnector? connector,
    Duration? handshakeTimeout,
  }) : _identity = identity ?? IdentityService.instance,
       _connector = connector ?? _defaultConnector,
       _handshakeTimeout =
           handshakeTimeout ?? AppConstants.relayHandshakeTimeout;

  static Future<WebSocket> _defaultConnector(
    Uri uri,
    Map<String, dynamic> headers,
  ) {
    return WebSocket.connect(uri.toString(), headers: headers);
  }

  RelayConfig get config => _config;

  RelayConnectionState get state => _state;

  bool get isConnected => _state == RelayConnectionState.connected;

  Stream<RelayConnectionState> get stateChanges => _stateController.stream;

  /// Application messages forwarded from peers.
  Stream<RelayInboundPayload> get payloads => _payloadController.stream;

  Stream<RelayPresenceEvent> get presenceChanges => _presenceController.stream;

  /// Peers currently known to be online, among those subscribed to.
  Set<String> get onlinePeers => Set.unmodifiable(_onlinePeers);

  bool isOnline(String deviceId) => _onlinePeers.contains(deviceId);

  /// Applies new settings, reconnecting only if something actually changed.
  ///
  /// Same config after an intentional [disconnect] (e.g. HTTP server restart
  /// on Wi‑Fi switch) still reconnects — otherwise [RelayService.start] would
  /// no-op and presence / scan would stay empty until the user toggles relay.
  Future<void> applyConfig(RelayConfig config) async {
    if (_config == config) {
      if (config.isActive && !isConnected) {
        _reconnectAttempt = 0;
        unawaited(connect());
      }
      return;
    }
    _config = config;
    _reconnectAttempt = 0;

    await _teardown();
    if (!config.isActive) {
      _setState(RelayConnectionState.disabled);
      return;
    }
    unawaited(connect());
  }

  /// Connects and completes the admission handshake.
  ///
  /// Returns whether the client ended up authenticated. Safe to call while a
  /// connection attempt is already running; callers share the same attempt.
  Future<bool> connect() async {
    if (_disposed) {
      return false;
    }
    if (_state == RelayConnectionState.connected) {
      return true;
    }

    final inFlight = _handshake;
    if (inFlight != null) {
      return inFlight.future;
    }

    if (!_config.isActive) {
      _setState(RelayConnectionState.disabled);
      return false;
    }

    final signalUri = _config.signalUri;
    if (signalUri == null) {
      LogUtil.wTag(logTag, '中转服务器地址无效: ${_config.serverUrl}');
      _setState(RelayConnectionState.rejected);
      return false;
    }

    final handshake = Completer<bool>();
    _handshake = handshake;
    _setState(
      _reconnectAttempt == 0
          ? RelayConnectionState.connecting
          : RelayConnectionState.reconnecting,
    );

    try {
      final socket = await _connector(signalUri, {
        HttpHeaders.authorizationHeader: 'Bearer ${_config.token}',
      }).timeout(_handshakeTimeout);

      _socket = socket;
      _socketSubscription = socket.listen(
        _onFrame,
        onError: (Object error) => _onSocketClosed('socket error: $error'),
        onDone: () => _onSocketClosed('closed by server'),
        cancelOnError: true,
      );

      // The server speaks first with its challenge; the rest of the handshake
      // happens in _onFrame, which completes this future.
      return await handshake.future.timeout(
        _handshakeTimeout,
        onTimeout: () {
          LogUtil.wTag(logTag, '中转握手超时');
          unawaited(_teardown(transient: true));
          _scheduleReconnect();
          // Nothing else will ever finish this attempt: the teardown above
          // detaches the socket, so _onSocketClosed returns early and never
          // fires. Left pending, _handshake would make every later connect()
          // await a future that can never complete.
          _completeHandshake(false);
          return false;
        },
      );
    } on WebSocketException catch (e) {
      LogUtil.wTag(logTag, '中转连接失败: ${e.message}');
      final rejected = await _isTokenRejected(signalUri);
      await _teardown(transient: !rejected);

      if (rejected) {
        _setState(RelayConnectionState.rejected);
      } else {
        _scheduleReconnect();
      }
      // Completed last, so a caller awaiting this attempt never observes the
      // transient state the failure was still being classified in.
      _completeHandshake(false);
      return false;
    } catch (e) {
      LogUtil.wTag(logTag, '中转连接失败: $e');
      await _teardown(transient: true);
      _scheduleReconnect();
      _completeHandshake(false);
      return false;
    }
  }

  /// Closes the connection and stops retrying until told otherwise.
  Future<void> disconnect() async {
    _reconnectAttempt = 0;
    await _teardown();
    _setState(RelayConnectionState.disabled);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _teardown();
    await _stateController.close();
    await _payloadController.close();
    await _presenceController.close();
    await _errorController.close();
  }

  /// Replaces the set of peers whose presence this device wants to see.
  ///
  /// Remembered across reconnects, since the server forgets subscriptions when
  /// the socket drops.
  Future<void> setSubscriptions(Iterable<String> deviceIds) async {
    final next = deviceIds.where((id) => id.isNotEmpty).toSet();
    _subscriptions
      ..clear()
      ..addAll(next);

    // Peers no longer watched can no longer be known to be online.
    _onlinePeers.removeWhere((id) => !next.contains(id));

    if (!isConnected) {
      return;
    }
    if (!_send(
      RelayEnvelope.build(
        RelayMessageType.subscribe,
        fields: {'peers': next.toList()},
      ),
    )) {
      LogUtil.wTag(logTag, '同步订阅列表失败');
    }
  }

  /// Forwards an application message to a peer through the relay.
  Future<OperationResult<void>> sendPayload({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    String kind = RelayKind.transfer,
  }) async {
    if (!isConnected) {
      return OperationResult.failure('未连接到中转服务器');
    }

    if (!_send(
      RelayEnvelope.build(
        RelayMessageType.relay,
        fields: {
          'to': toDeviceId,
          'kind': kind,
          'payload': encodeRelayPayload(payload),
        },
      ),
    )) {
      return OperationResult.failure('发送中转消息失败');
    }
    return OperationResult.success();
  }

  /// Sends an application message and waits for the peer's answer.
  ///
  /// The reply is matched on its contents rather than on a message id, because
  /// the answer is a new message from the peer rather than a response from the
  /// server. Server-side failures — most importantly the peer having gone
  /// offline — do carry the request's id, so they fail the wait immediately
  /// instead of leaving the caller to sit out the whole timeout.
  Future<OperationResult<Map<String, dynamic>>> sendAndAwaitReply({
    required String toDeviceId,
    required Map<String, dynamic> payload,
    required bool Function(Map<String, dynamic> reply) matches,
    required Duration timeout,
    String kind = RelayKind.transfer,
  }) async {
    if (!isConnected) {
      return OperationResult.failure('未连接到中转服务器');
    }

    final mid = 'm${++_messageCounter}';
    final completer = Completer<OperationResult<Map<String, dynamic>>>();

    void finish(OperationResult<Map<String, dynamic>> result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    final replies = _payloadController.stream.listen((inbound) {
      if (inbound.fromDeviceId == toDeviceId && matches(inbound.payload)) {
        finish(OperationResult.success(data: inbound.payload));
      }
    });
    final errors = _errorController.stream.listen((event) {
      if (event.mid == mid) {
        finish(
          OperationResult.failure(_describeError(event.code, event.message)),
        );
      }
    });

    try {
      if (!_send(
        RelayEnvelope.build(
          RelayMessageType.relay,
          mid: mid,
          fields: {
            'to': toDeviceId,
            'kind': kind,
            'payload': encodeRelayPayload(payload),
          },
        ),
      )) {
        return OperationResult.failure('发送中转消息失败');
      }

      return await completer.future.timeout(
        timeout,
        onTimeout: () => OperationResult.failure('对方设备没有响应'),
      );
    } finally {
      await replies.cancel();
      await errors.cancel();
    }
  }

  /// Waits for a peer message matching [matches], without sending anything.
  ///
  /// Used to arm a listener before an action that will provoke the reply, so
  /// an answer arriving quickly cannot be missed.
  Future<OperationResult<Map<String, dynamic>>> awaitPayload({
    required String fromDeviceId,
    required bool Function(Map<String, dynamic> payload) matches,
    required Duration timeout,
  }) async {
    try {
      final inbound = await _payloadController.stream
          .firstWhere(
            (event) =>
                event.fromDeviceId == fromDeviceId && matches(event.payload),
          )
          .timeout(timeout);
      return OperationResult.success(data: inbound.payload);
    } on TimeoutException {
      return OperationResult.failure('对方设备没有响应');
    } catch (e) {
      return OperationResult.failure('等待对方响应失败: $e');
    }
  }

  /// Asks the relay for a data stream towards [peerDeviceId].
  Future<OperationResult<String>> createStream({
    required String peerDeviceId,
    required String role,
  }) async {
    final response = await _request(
      RelayMessageType.streamCreate,
      fields: {'peer': peerDeviceId, 'role': role},
    );

    if (!response.isSuccess) {
      return OperationResult.failure(response.errorMessage!);
    }

    final streamId = response.data!.streamId;
    if (streamId == null) {
      return OperationResult.failure('中转服务器未返回数据流标识');
    }
    return OperationResult.success(data: streamId);
  }

  Uri? streamUri(String streamId) => _config.streamUri(streamId);

  /// Headers proving to the data plane that this device may attach.
  ///
  /// The proof is bound to the stream id, so a header set captured from one
  /// upload cannot be replayed against another stream.
  Future<Map<String, String>> streamHeaders(String streamId) async {
    final deviceId = await _identity.getDeviceId();
    final proof = await _identity.sign(
      _streamProofMessage(streamId),
    );

    return {
      HttpHeaders.authorizationHeader: 'Bearer ${_config.token}',
      'X-Device-Id': deviceId,
      'X-Stream-Proof': base64Encode(proof),
    };
  }

  // -- internals ------------------------------------------------------------

  void _onFrame(dynamic frame) {
    if (frame is! String) {
      return;
    }

    final envelope = RelayEnvelope.decode(frame);
    if (envelope == null) {
      LogUtil.wTag(logTag, '收到无法解析的中转报文');
      return;
    }

    switch (envelope.type) {
      case RelayMessageType.challenge:
        unawaited(_answerChallenge(envelope));
      case RelayMessageType.welcome:
        _onWelcome(envelope);
      case RelayMessageType.presence:
        _onPresence(envelope);
      case RelayMessageType.relay:
        _onRelayed(envelope);
      case RelayMessageType.streamCreated:
      case RelayMessageType.pong:
        _completeRequest(envelope);
      case RelayMessageType.error:
        _onError(envelope);
      default:
        LogUtil.dTag(logTag, '忽略未知中转报文类型: ${envelope.type}');
    }
  }

  Future<void> _answerChallenge(RelayEnvelope envelope) async {
    final nonce = envelope.nonce;
    if (nonce == null) {
      LogUtil.wTag(logTag, '中转挑战缺少 nonce');
      return;
    }

    try {
      final deviceId = await _identity.getDeviceId();
      final publicKey = await _identity.getPublicKeyBase64();
      final signature = await _identity.sign(
        _authMessage(base64Decode(nonce), deviceId),
      );

      _send(
        RelayEnvelope.build(
          RelayMessageType.auth,
          fields: {
            'deviceId': deviceId,
            'publicKey': publicKey,
            'signature': base64Encode(signature),
          },
        ),
      );
    } catch (e) {
      LogUtil.eTag(logTag, '无法完成中转身份认证: $e');
      await _teardown(transient: true);
      _scheduleReconnect();
      _completeHandshake(false);
    }
  }

  void _onWelcome(RelayEnvelope envelope) {
    _reconnectAttempt = 0;
    _setState(RelayConnectionState.connected);
    _completeHandshake(true);

    LogUtil.iTag(
      logTag,
      '已连接中转服务器: ${_config.displayHost}, 会话=${envelope.sessionId}',
    );

    // The server has no memory of what this device was watching, so the
    // subscription set is replayed on every connection.
    if (_subscriptions.isNotEmpty) {
      _send(
        RelayEnvelope.build(
          RelayMessageType.subscribe,
          fields: {'peers': _subscriptions.toList()},
        ),
      );
    }

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(AppConstants.relayPingInterval, (_) {
      if (isConnected) {
        _send(RelayEnvelope.build(RelayMessageType.ping));
      }
    });
  }

  void _onPresence(RelayEnvelope envelope) {
    final deviceId = envelope.deviceId;
    if (deviceId == null) {
      return;
    }

    final online = envelope.online;
    final changed = online
        ? _onlinePeers.add(deviceId)
        : _onlinePeers.remove(deviceId);
    if (!changed) {
      return;
    }

    _presenceController.add(
      RelayPresenceEvent(deviceId: deviceId, online: online),
    );
  }

  void _onRelayed(RelayEnvelope envelope) {
    final from = envelope.from;
    if (from == null) {
      return;
    }

    final payload = decodeRelayPayload(envelope.payload);
    if (payload == null) {
      LogUtil.wTag(logTag, '来自 ${_short(from)} 的中转消息无法解析');
      return;
    }

    _delivery = _delivery
        .then((_) => _deliver(from, payload))
        .catchError((Object error, StackTrace stack) {
          LogUtil.eTag(logTag, '处理中转消息失败: $error', error, stack);
        });
  }

  Future<void> _deliver(String from, Map<String, dynamic> payload) async {
    var delivered = payload;

    if (payload['type'] == RelayPayloadType.secure) {
      final opened = await sessions.open(from, payload);
      if (opened == null) {
        // Either there is no session for it or it failed to authenticate.
        // Both mean the message did not come from the peer it claims to, so
        // it is dropped without an answer that would confirm anything.
        LogUtil.wTag(logTag, '丢弃无法解密的中转消息: ${_short(from)}');
        return;
      }
      delivered = opened;
    }

    if (_payloadController.isClosed) {
      return;
    }
    _payloadController.add(
      RelayInboundPayload(fromDeviceId: from, payload: delivered),
    );
  }

  void _onError(RelayEnvelope envelope) {
    final code = envelope.code ?? RelayErrorCode.internal;

    // An error answering a specific request belongs to that request; a
    // connection-level error means the session itself is over.
    if (_completeRequest(envelope)) {
      return;
    }

    if (!_errorController.isClosed) {
      _errorController.add(
        RelayErrorEvent(
          code: code,
          mid: envelope.mid,
          message: envelope.message,
        ),
      );
    }

    LogUtil.wTag(logTag, '中转服务器返回错误: $code ${envelope.message ?? ''}');
    if (code == RelayErrorCode.unauthorized ||
        code == RelayErrorCode.badIdentity) {
      unawaited(_teardown());
      _setState(RelayConnectionState.rejected);
      _completeHandshake(false);
    }
  }

  /// Sends a message and waits for the reply carrying the same `mid`.
  Future<OperationResult<RelayEnvelope>> _request(
    String type, {
    Map<String, dynamic> fields = const {},
  }) async {
    if (!isConnected) {
      return OperationResult.failure('未连接到中转服务器');
    }

    final mid = 'm${++_messageCounter}';
    final completer = Completer<RelayEnvelope>();
    _pendingRequests[mid] = completer;

    if (!_send(RelayEnvelope.build(type, mid: mid, fields: fields))) {
      _pendingRequests.remove(mid);
      return OperationResult.failure('发送中转消息失败');
    }

    try {
      final response = await completer.future.timeout(
        AppConstants.relayRequestTimeout,
      );
      if (response.type == RelayMessageType.error) {
        return OperationResult.failure(
          _describeError(response.code, response.message),
        );
      }
      return OperationResult.success(data: response);
    } on TimeoutException {
      return OperationResult.failure('中转服务器响应超时');
    } finally {
      _pendingRequests.remove(mid);
    }
  }

  /// Routes a reply to whoever is waiting for it.
  ///
  /// Returns whether the message was claimed by a pending request.
  bool _completeRequest(RelayEnvelope envelope) {
    final mid = envelope.mid;
    if (mid == null) {
      return false;
    }

    final pending = _pendingRequests.remove(mid);
    if (pending == null || pending.isCompleted) {
      return false;
    }
    pending.complete(envelope);
    return true;
  }

  bool _send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null) {
      return false;
    }
    try {
      socket.add(jsonEncode(message));
      return true;
    } catch (e) {
      LogUtil.wTag(logTag, '发送中转报文失败: $e');
      return false;
    }
  }

  /// Tells a refused token apart from a broken network.
  ///
  /// The distinction decides whether to keep retrying, so guessing is not an
  /// option: a wrong token would otherwise be retried forever against
  /// somebody's VPS. `WebSocket.connect` reports a failed upgrade without the
  /// status code, so the status is fetched with a plain GET. The relay checks
  /// the token before attempting the upgrade, which makes the two cases
  /// distinguishable: a valid token answers 400 because the request is not a
  /// WebSocket handshake, a wrong one answers 401.
  Future<bool> _isTokenRejected(Uri signalUri) async {
    final client = HttpClient()
      ..connectionTimeout = AppConstants.relayRequestTimeout;

    try {
      final probeUri = signalUri.replace(
        scheme: signalUri.scheme == 'wss' ? 'https' : 'http',
      );
      final request = await client.getUrl(probeUri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${_config.token}',
      );

      final response = await request.close().timeout(
        AppConstants.relayRequestTimeout,
      );
      await response.drain<void>();

      return response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden;
    } catch (_) {
      // Unreachable rather than refused, so it is worth retrying.
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _onSocketClosed(String reason) {
    if (_socket == null) {
      return;
    }

    LogUtil.wTag(logTag, '中转连接断开: $reason');
    unawaited(_teardown(transient: true));

    if (_state != RelayConnectionState.rejected) {
      _scheduleReconnect();
    }
    _completeHandshake(false);
  }

  void _scheduleReconnect() {
    if (_disposed || !_config.isActive) {
      _setState(RelayConnectionState.disabled);
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _backoffDelay(_reconnectAttempt++);
    _setState(RelayConnectionState.reconnecting);

    LogUtil.dTag(logTag, '${delay.inSeconds} 秒后重连中转服务器');
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && _config.isActive) {
        unawaited(connect());
      }
    });
  }

  /// Exponential backoff, so a relay that is down does not get hammered by
  /// every client that has it configured.
  static Duration _backoffDelay(int attempt) {
    final seconds =
        AppConstants.relayReconnectMinDelay.inSeconds * pow(2, attempt).toInt();
    return Duration(
      seconds: min(seconds, AppConstants.relayReconnectMaxDelay.inSeconds),
    );
  }

  Future<void> _teardown({bool transient = false}) async {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (!transient) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    final subscription = _socketSubscription;
    _socketSubscription = null;
    final socket = _socket;
    _socket = null;

    await subscription?.cancel();
    try {
      await socket?.close();
    } catch (_) {
      // Already gone; nothing useful to do about it.
    }

    for (final pending in _pendingRequests.values) {
      if (!pending.isCompleted) {
        pending.completeError(StateError('中转连接已断开'));
      }
    }
    _pendingRequests.clear();

    if (!transient) {
      _onlinePeers.clear();
      // Intentional shutdown or a new config: drop negotiated keys.
      sessions.clear();
      // The connection is gone for good, so an attempt still in flight will
      // never be finished by anything else. Resetting the state matters just
      // as much: left at `connected`, the next connect() would return true
      // without reconnecting, which is what made a relay server change look
      // like it had worked.
      _setState(RelayConnectionState.disabled);
      _completeHandshake(false);
    }
  }

  void _completeHandshake(bool success) {
    final handshake = _handshake;
    _handshake = null;
    if (handshake != null && !handshake.isCompleted) {
      handshake.complete(success);
    }
  }

  void _setState(RelayConnectionState state) {
    if (_state == state || _stateController.isClosed) {
      return;
    }
    _state = state;
    _stateController.add(state);
  }

  /// `"icy-relay-auth-v1" ‖ nonce ‖ deviceId`, with the device id contributing
  /// its 32 ASCII hex characters. Must match `auth.AuthMessage` on the server.
  static Uint8List _authMessage(List<int> nonce, String deviceId) {
    return Uint8List.fromList([
      ...utf8.encode(AppConstants.relayAuthContext),
      ...nonce,
      ...utf8.encode(deviceId),
    ]);
  }

  /// `"icy-relay-stream-v1" ‖ streamId`. Must match `auth.StreamMessage`.
  static Uint8List _streamProofMessage(String streamId) {
    return Uint8List.fromList([
      ...utf8.encode(AppConstants.relayStreamContext),
      ...utf8.encode(streamId),
    ]);
  }

  static String _describeError(String? code, String? message) {
    switch (code) {
      case RelayErrorCode.peerOffline:
        return '对方设备不在中转服务器上';
      case RelayErrorCode.tooManyStreams:
        return '并发传输数超过中转服务器上限';
      case RelayErrorCode.rateLimited:
        return '请求过于频繁，请稍后再试';
      case RelayErrorCode.unauthorized:
        return '中转服务器拒绝了接入令牌';
      case RelayErrorCode.badIdentity:
        return '中转服务器拒绝了设备身份';
      default:
        return message ?? (code ?? '中转服务器返回未知错误');
    }
  }

  static String _short(String deviceId) =>
      deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
}
