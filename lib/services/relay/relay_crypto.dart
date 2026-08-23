import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../utils/constants.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../identity_service.dart';
import 'relay_protocol.dart';

/// Which end of a session this device is on.
///
/// The two ends encrypt with different keys, so every operation needs to know
/// which one it is.
enum RelayRole { sender, receiver }

/// End-to-end encryption for relayed transfers.
///
/// The relay is assumed hostile: it can read, drop, reorder and forge anything
/// on the signaling plane. What it cannot do is produce a signature over the
/// handshake transcript, which is what every guarantee here rests on.
///
/// The shape is TLS 1.3's, reduced to what two already-paired devices need:
/// an ephemeral X25519 exchange for forward secrecy, then a signature from
/// each side over a transcript covering both halves. Long-term keys are only
/// ever used to sign, never to encrypt, so a stolen `identity.key` cannot
/// decrypt anything that was captured earlier.
class RelayCrypto {
  const RelayCrypto._();

  static final X25519 _keyExchange = X25519();
  static final Sha256 _sha256 = Sha256();
  static final Chacha20 _aead = Chacha20.poly1305Aead();

  /// Domain separators for the two signatures, so a message signed by the
  /// sender can never be replayed as if the receiver had signed it.
  static const String _senderTag = 'S';
  static const String _receiverTag = 'R';

  static const int _nonceBytes = 16;

  /// Starts a handshake, keeping the ephemeral private key on this side.
  static Future<RelayPendingOffer> createOffer(String sessionId) async {
    final ephemeral = await _keyExchange.newKeyPair();
    final publicKey = await ephemeral.extractPublicKey();

    return RelayPendingOffer._(
      sessionId: sessionId,
      keyPair: ephemeral,
      publicKey: Uint8List.fromList(publicKey.bytes),
      nonce: _randomBytes(_nonceBytes),
    );
  }

  /// Receiver side: answers an offer and derives the session keys.
  ///
  /// The answer is signed here; the sender's own signature only arrives with
  /// the manifest, which is why nothing may be accepted from this session
  /// until that signature has been checked.
  static Future<OperationResult<RelayAnsweredSession>> answerOffer({
    required TransferOffer offer,
    required String senderDeviceId,
    required String receiverDeviceId,
    IdentityService? identity,
  }) async {
    final senderEphemeral = _decodeKey(offer.ephemeralPublicKey);
    final senderNonce = _decodeBytes(offer.nonce);
    if (senderEphemeral == null || senderNonce == null) {
      return OperationResult.failure('中转会话请求无效');
    }

    final ephemeral = await _keyExchange.newKeyPair();
    final publicKey = Uint8List.fromList(
      (await ephemeral.extractPublicKey()).bytes,
    );
    final nonce = _randomBytes(_nonceBytes);

    final transcript = await computeTranscript(
      sessionId: offer.sessionId,
      senderDeviceId: senderDeviceId,
      receiverDeviceId: receiverDeviceId,
      senderEphemeral: senderEphemeral,
      receiverEphemeral: publicKey,
      senderNonce: senderNonce,
      receiverNonce: nonce,
    );

    final keys = await _deriveKeys(
      keyPair: ephemeral,
      peerPublicKey: senderEphemeral,
      transcript: transcript,
    );

    final signature = await (identity ?? IdentityService.instance).sign(
      _signedTranscript(_receiverTag, transcript),
    );

    return OperationResult.success(
      data: RelayAnsweredSession._(
        answer: TransferAnswer(
          sessionId: offer.sessionId,
          ephemeralPublicKey: base64Encode(publicKey),
          nonce: base64Encode(nonce),
          signature: base64Encode(signature),
        ),
        session: RelaySecureSession._(
          sessionId: offer.sessionId,
          peerDeviceId: senderDeviceId,
          role: RelayRole.receiver,
          keys: keys,
          transcript: transcript,
        ),
      ),
    );
  }

  /// Sender side: verifies the receiver's signature and derives the keys.
  ///
  /// A wrong signature here means the device answering is not the one that was
  /// paired with, whatever `from` on the envelope claims.
  static Future<OperationResult<RelaySecureSession>> completeOffer({
    required RelayPendingOffer offer,
    required TransferAnswer answer,
    required String senderDeviceId,
    required String receiverDeviceId,
    required List<int> receiverPublicKey,
  }) async {
    final receiverEphemeral = _decodeKey(answer.ephemeralPublicKey);
    final receiverNonce = _decodeBytes(answer.nonce);
    final signature = _decodeBytes(answer.signature);
    if (receiverEphemeral == null ||
        receiverNonce == null ||
        signature == null) {
      return OperationResult.failure('中转会话应答无效');
    }

    final transcript = await computeTranscript(
      sessionId: offer.sessionId,
      senderDeviceId: senderDeviceId,
      receiverDeviceId: receiverDeviceId,
      senderEphemeral: offer.publicKey,
      receiverEphemeral: receiverEphemeral,
      senderNonce: offer.nonce,
      receiverNonce: receiverNonce,
    );

    final verified = await IdentityService.verify(
      _signedTranscript(_receiverTag, transcript),
      signature: signature,
      publicKey: receiverPublicKey,
    );
    if (!verified) {
      LogUtil.wTag(LogTags.transfer, '中转会话应答签名无效，对方可能不是已配对设备');
      return OperationResult.failure('对方设备的身份签名无效');
    }

    final keys = await _deriveKeys(
      keyPair: offer.keyPair,
      peerPublicKey: receiverEphemeral,
      transcript: transcript,
    );

    return OperationResult.success(
      data: RelaySecureSession._(
        sessionId: offer.sessionId,
        peerDeviceId: receiverDeviceId,
        role: RelayRole.sender,
        keys: keys,
        transcript: transcript,
      ),
    );
  }

  /// The sender's proof of identity, sent with the manifest.
  static Future<String> signAsSender(
    Uint8List transcript, {
    IdentityService? identity,
  }) async {
    final signature = await (identity ?? IdentityService.instance).sign(
      _signedTranscript(_senderTag, transcript),
    );
    return base64Encode(signature);
  }

  /// Checks the signature a manifest carries against the paired public key.
  static Future<bool> verifySenderSignature({
    required Uint8List transcript,
    required String signature,
    required List<int> senderPublicKey,
  }) async {
    final decoded = _decodeBytes(signature);
    if (decoded == null) {
      return false;
    }
    return IdentityService.verify(
      _signedTranscript(_senderTag, transcript),
      signature: decoded,
      publicKey: senderPublicKey,
    );
  }

  /// `SHA-256("icy-relay-hs-v1" ‖ sid ‖ deviceId_S ‖ deviceId_R ‖ epk_s ‖
  /// epk_r ‖ n_s ‖ n_r)`.
  ///
  /// Every value either side chose is in here, which is what makes the two
  /// signatures cover the whole exchange rather than just one message. Ids and
  /// the session id contribute their ASCII characters, matching the convention
  /// the admission handshake already uses.
  static Future<Uint8List> computeTranscript({
    required String sessionId,
    required String senderDeviceId,
    required String receiverDeviceId,
    required List<int> senderEphemeral,
    required List<int> receiverEphemeral,
    required List<int> senderNonce,
    required List<int> receiverNonce,
  }) async {
    final digest = await _sha256.hash([
      ...utf8.encode(AppConstants.relayHandshakeContext),
      ...utf8.encode(sessionId),
      ...utf8.encode(senderDeviceId),
      ...utf8.encode(receiverDeviceId),
      ...senderEphemeral,
      ...receiverEphemeral,
      ...senderNonce,
      ...receiverNonce,
    ]);
    return Uint8List.fromList(digest.bytes);
  }

  static Future<RelaySessionKeys> _deriveKeys({
    required SimpleKeyPair keyPair,
    required List<int> peerPublicKey,
    required Uint8List transcript,
  }) async {
    final shared = await _keyExchange.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        peerPublicKey,
        type: KeyPairType.x25519,
      ),
    );

    return RelaySessionKeys._(
      sharedSecret: shared,
      transcript: transcript,
      senderToReceiver: SecretKey(
        await _expand(shared, transcript, AppConstants.relayLabelSenderToReceiver, 32),
      ),
      receiverToSender: SecretKey(
        await _expand(shared, transcript, AppConstants.relayLabelReceiverToSender, 32),
      ),
    );
  }

  /// HKDF with the transcript as salt.
  ///
  /// `cryptography` fuses extract and expand into one call, so passing the
  /// same secret and salt every time is what gives all the labels a common
  /// pseudorandom key, exactly as the two-step form in the design does.
  static Future<Uint8List> _expand(
    SecretKey sharedSecret,
    Uint8List transcript,
    String label,
    int length,
  ) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: length);
    final key = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: transcript,
      info: utf8.encode(label),
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  static Uint8List _signedTranscript(String tag, Uint8List transcript) {
    return Uint8List.fromList([...utf8.encode(tag), ...transcript]);
  }

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      SecretKeyData.random(length: length).bytes,
    );
  }

  static Uint8List? _decodeBytes(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      return null;
    }
  }

  /// Decodes a 32-byte X25519 public key, rejecting anything else.
  static Uint8List? _decodeKey(String value) {
    final bytes = _decodeBytes(value);
    if (bytes == null || bytes.length != 32) {
      return null;
    }
    return bytes;
  }
}

/// A handshake this device started, waiting for the peer's answer.
class RelayPendingOffer {
  final String sessionId;
  final SimpleKeyPair keyPair;
  final Uint8List publicKey;
  final Uint8List nonce;

  const RelayPendingOffer._({
    required this.sessionId,
    required this.keyPair,
    required this.publicKey,
    required this.nonce,
  });

  TransferOffer get payload => TransferOffer(
    sessionId: sessionId,
    ephemeralPublicKey: base64Encode(publicKey),
    nonce: base64Encode(nonce),
  );
}

/// The receiver's answer plus the session it just established.
class RelayAnsweredSession {
  final TransferAnswer answer;
  final RelaySecureSession session;

  const RelayAnsweredSession._({required this.answer, required this.session});
}

/// Everything derived from one handshake.
class RelaySessionKeys {
  final SecretKey _sharedSecret;
  final Uint8List transcript;

  /// Direction keys for the signaling messages.
  final SecretKey senderToReceiver;
  final SecretKey receiverToSender;

  const RelaySessionKeys._({
    required SecretKey sharedSecret,
    required this.transcript,
    required this.senderToReceiver,
    required this.receiverToSender,
  }) : _sharedSecret = sharedSecret;

  /// Key and nonce prefix for one attempt at one file's bulk encryption.
  ///
  /// Per file rather than per session so that two files being sent at once
  /// cannot land on the same nonce: each gets its own key, so each gets its
  /// own chunk counter space.
  ///
  /// Per [attempt] as well, because a retry re-sends chunks the previous
  /// attempt already sent, under their original chunk numbers. The nonce is
  /// derived from the chunk number, so without this those chunks would be a
  /// second encryption under a nonce that had already been used. If the file
  /// changed on disk in between — a log still being written to, say — the two
  /// plaintexts would differ, and two different plaintexts under one key and
  /// nonce is the one thing ChaCha20-Poly1305 must never be asked to do. A
  /// fresh key per attempt makes the question moot.
  Future<RelayFileKey> fileKey(String fileId, {int attempt = 0}) async {
    final scope = '$fileId#$attempt';
    final key = await RelayCrypto._expand(
      _sharedSecret,
      transcript,
      '${AppConstants.relayLabelFileKey}$scope',
      32,
    );
    final noncePrefix = await RelayCrypto._expand(
      _sharedSecret,
      transcript,
      '${AppConstants.relayLabelFileNonce}$scope',
      4,
    );
    return RelayFileKey(
      fileId: fileId,
      key: key,
      noncePrefix: noncePrefix,
    );
  }
}

/// Bulk encryption material for a single file.
class RelayFileKey {
  final String fileId;
  final Uint8List key;
  final Uint8List noncePrefix;

  RelayFileKey({
    required this.fileId,
    required this.key,
    required this.noncePrefix,
  }) : _fileIdBytes = _decodeFileId(fileId);

  /// `nprefix ‖ chunkIndex`, 12 bytes, unique per chunk under this key.
  Uint8List nonceFor(int chunkIndex) {
    final nonce = Uint8List(12)..setRange(0, 4, noncePrefix);
    final view = ByteData.view(nonce.buffer);
    view.setUint64(4, chunkIndex, Endian.big);
    return nonce;
  }

  /// `fileId ‖ chunkIndex ‖ isFinal`, bound into every frame.
  ///
  /// The final flag is the anti-truncation measure: a stream cut short ends on
  /// a frame whose additional data says more are coming, and no frame can be
  /// moved to another position without its index failing to match.
  Uint8List aadFor(int chunkIndex, {required bool isFinal}) {
    final aad = Uint8List(25);
    aad.setRange(0, 16, _fileIdBytes);
    ByteData.view(aad.buffer).setUint64(16, chunkIndex, Endian.big);
    aad[24] = isFinal ? 1 : 0;
    return aad;
  }

  /// The 32 hex characters of the file id as the 16 bytes they encode.
  final Uint8List _fileIdBytes;

  static Uint8List _decodeFileId(String fileId) {
    final bytes = Uint8List(16);
    for (var i = 0; i < 16 && (i * 2 + 1) < fileId.length; i++) {
      bytes[i] =
          int.tryParse(fileId.substring(i * 2, i * 2 + 2), radix: 16) ?? 0;
    }
    return bytes;
  }
}

/// One authenticated session with one peer.
///
/// Wraps and unwraps the signaling messages that describe a transfer. The
/// sequence number is both the nonce source and the replay guard, which is why
/// it is per session and strictly increasing.
class RelaySecureSession {
  final String sessionId;
  final String peerDeviceId;
  final RelayRole role;
  final RelaySessionKeys keys;
  final Uint8List transcript;

  int _sendSequence = 0;
  int _highestReceived = -1;

  RelaySecureSession._({
    required this.sessionId,
    required this.peerDeviceId,
    required this.role,
    required this.keys,
    required this.transcript,
  });

  SecretKey get _outbound => role == RelayRole.sender
      ? keys.senderToReceiver
      : keys.receiverToSender;

  SecretKey get _inbound => role == RelayRole.sender
      ? keys.receiverToSender
      : keys.senderToReceiver;

  /// Wraps an application message for the wire.
  Future<Map<String, dynamic>> seal(Map<String, dynamic> payload) async {
    final sequence = _sendSequence++;
    final box = await RelayCrypto._aead.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: _outbound,
      nonce: _signalNonce(sequence),
      aad: _signalAad(sequence),
    );

    return {
      'type': RelayPayloadType.secure,
      'sid': sessionId,
      'seq': sequence,
      'ct': base64Encode([...box.cipherText, ...box.mac.bytes]),
    };
  }

  /// Unwraps a message, returning null when it is not authentic.
  ///
  /// Every rejection here is silent by design: a relay that tampers should
  /// learn nothing about which of its guesses was closer.
  Future<Map<String, dynamic>?> open(Map<String, dynamic> wrapper) async {
    final sequence = wrapper['seq'];
    final ciphertext = wrapper['ct'];
    if (sequence is! int || ciphertext is! String) {
      return null;
    }
    if (wrapper['sid'] != sessionId) {
      return null;
    }
    // Strictly increasing: the relay preserves order within a connection, so
    // anything that goes backwards is a replay rather than a reordering.
    if (sequence <= _highestReceived) {
      LogUtil.wTag(LogTags.transfer, '丢弃重放的中转消息: seq=$sequence');
      return null;
    }

    final raw = RelayCrypto._decodeBytes(ciphertext);
    if (raw == null || raw.length < AppConstants.relayAeadTagBytes) {
      return null;
    }

    final split = raw.length - AppConstants.relayAeadTagBytes;
    try {
      final clear = await RelayCrypto._aead.decrypt(
        SecretBox(
          raw.sublist(0, split),
          nonce: _signalNonce(sequence),
          mac: Mac(raw.sublist(split)),
        ),
        secretKey: _inbound,
        aad: _signalAad(sequence),
      );

      final decoded = jsonDecode(utf8.decode(clear));
      if (decoded is! Map<String, dynamic> || decoded['type'] is! String) {
        return null;
      }
      _highestReceived = sequence;
      return decoded;
    } catch (e) {
      LogUtil.wTag(LogTags.transfer, '中转消息解密失败: $e');
      return null;
    }
  }

  Uint8List _signalNonce(int sequence) {
    final nonce = Uint8List(12);
    ByteData.view(nonce.buffer).setUint64(4, sequence, Endian.big);
    return nonce;
  }

  Uint8List _signalAad(int sequence) {
    final prefix = utf8.encode(AppConstants.relaySignalingContext);
    final id = utf8.encode(sessionId);
    final aad = Uint8List(prefix.length + id.length + 8);
    aad.setRange(0, prefix.length, prefix);
    aad.setRange(prefix.length, prefix.length + id.length, id);
    ByteData.view(aad.buffer).setUint64(
      prefix.length + id.length,
      sequence,
      Endian.big,
    );
    return aad;
  }
}

/// The sessions this device currently holds, keyed by session id.
///
/// Lives on the [RelayClient] so inbound messages can be decrypted before
/// anything else sees them: the rest of the app then works with plaintext and
/// never has to remember which messages were supposed to be encrypted.
class RelaySessionRegistry {
  final Map<String, RelaySecureSession> _sessions = {};

  void add(RelaySecureSession session) {
    _sessions[session.sessionId] = session;
  }

  RelaySecureSession? find(String sessionId) => _sessions[sessionId];

  void remove(String sessionId) {
    _sessions.remove(sessionId);
  }

  void clear() => _sessions.clear();

  int get length => _sessions.length;

  /// Decrypts a wrapper that arrived from [fromDeviceId].
  ///
  /// The peer is checked against the session rather than trusted from the
  /// envelope, so a third device cannot inject messages into a session by
  /// naming its id — it would also have to produce a valid tag.
  Future<Map<String, dynamic>?> open(
    String fromDeviceId,
    Map<String, dynamic> wrapper,
  ) async {
    final sessionId = wrapper['sid'];
    if (sessionId is! String) {
      return null;
    }

    final session = _sessions[sessionId];
    if (session == null || session.peerDeviceId != fromDeviceId) {
      return null;
    }
    return session.open(wrapper);
  }
}
