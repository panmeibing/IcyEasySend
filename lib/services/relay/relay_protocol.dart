/// Wire format of the relay signaling plane.
///
/// This file is the Dart half of `relay/internal/protocol/protocol.go`; the two
/// must be changed together. Everything the server can read lives here.
/// Everything it cannot read — file names, sizes, transfer decisions — travels
/// inside [RelayEnvelope.payload] and is defined further down this file.
library;

import 'dart:convert';

import '../../utils/constants.dart';

/// Signaling protocol version carried in every envelope.
const int relayProtocolVersion = 1;

/// Message types on the signaling plane.
class RelayMessageType {
  static const String challenge = 'challenge';
  static const String auth = 'auth';
  static const String welcome = 'welcome';
  static const String subscribe = 'subscribe';
  static const String presence = 'presence';
  static const String relay = 'relay';
  static const String streamCreate = 'stream.create';
  static const String streamCreated = 'stream.created';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String error = 'error';

  const RelayMessageType._();
}

/// Coarse classification of a relayed message, used by the server only for
/// rate limiting. It reveals nothing about the contents.
class RelayKind {
  static const String pair = 'pair';
  static const String transfer = 'transfer';

  const RelayKind._();
}

/// Which end of a data stream the caller intends to be.
class RelayStreamRole {
  static const String sender = 'sender';
  static const String receiver = 'receiver';

  const RelayStreamRole._();
}

/// Error codes shared by the signaling and data planes.
class RelayErrorCode {
  static const String unauthorized = 'unauthorized';
  static const String badIdentity = 'bad_identity';
  static const String badRequest = 'bad_request';
  static const String peerOffline = 'peer_offline';
  static const String streamNotFound = 'stream_not_found';
  static const String streamForbidden = 'stream_forbidden';
  static const String peerNotAttached = 'peer_not_attached';
  static const String tooManyStreams = 'too_many_streams';
  static const String payloadTooLarge = 'payload_too_large';
  static const String idleTimeout = 'idle_timeout';
  static const String rateLimited = 'rate_limited';
  static const String internal = 'internal';

  const RelayErrorCode._();
}

/// A decoded signaling message.
///
/// The protocol is small enough that one loosely typed envelope beats a class
/// hierarchy: each handler reads the two or three fields its type defines.
class RelayEnvelope {
  final Map<String, dynamic> raw;

  const RelayEnvelope(this.raw);

  /// Decodes a frame, returning null when it is not a usable message.
  ///
  /// Everything arriving here is untrusted, so malformed input is dropped
  /// rather than thrown.
  static RelayEnvelope? decode(String frame) {
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final type = decoded['type'];
      if (type is! String || type.isEmpty) {
        return null;
      }
      return RelayEnvelope(decoded);
    } catch (_) {
      return null;
    }
  }

  String get type => raw['type'] as String;

  String? get mid => _string('mid');

  String? get nonce => _string('nonce');

  String? get sessionId => _string('sessionId');

  String? get deviceId => _string('deviceId');

  String? get from => _string('from');

  String? get kind => _string('kind');

  String? get payload => _string('payload');

  String? get streamId => _string('streamId');

  String? get code => _string('code');

  String? get message => _string('message');

  bool get online => raw['online'] == true;

  int? get expiresAt {
    final value = raw['expiresAt'];
    return value is int ? value : null;
  }

  String? _string(String key) {
    final value = raw[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Builds an outbound message, stamping the version and timestamp.
  static Map<String, dynamic> build(
    String type, {
    String? mid,
    Map<String, dynamic> fields = const {},
  }) {
    return {
      'v': relayProtocolVersion,
      'type': type,
      'mid': ?mid,
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ...fields,
    };
  }

  @override
  String toString() => 'RelayEnvelope($type)';
}

// ---------------------------------------------------------------------------
// Application-layer messages
//
// These travel base64-encoded inside a relay envelope's payload.
//
// Only the pairing messages and the two handshake messages are readable on the
// wire, and they carry nothing but public keys and random numbers. Everything
// that describes a transfer travels inside a [RelayPayloadType.secure]
// wrapper, so the relay operator sees ciphertext where the file names, sizes
// and decisions would be.
// ---------------------------------------------------------------------------

/// Types of the messages exchanged inside a payload.
class RelayPayloadType {
  static const String transferOffer = 'transfer.offer';
  static const String transferAnswer = 'transfer.answer';
  static const String transferManifest = 'transfer.manifest';
  static const String transferAccept = 'transfer.accept';
  static const String fileBegin = 'file.begin';
  static const String fileDone = 'file.done';
  static const String transferCancel = 'transfer.cancel';

  /// Envelope holding any of the above once session keys exist.
  static const String secure = 'secure';

  static const String pairRequest = 'pair.request';
  /// Peer's public key, sent before either user has compared the digits so
  /// both screens can show the same code at once.
  static const String pairAnnounce = 'pair.announce';
  static const String pairResponse = 'pair.response';
  static const String pairConfirm = 'pair.confirm';

  static const String clipboardOffer = 'clipboard.offer';
  static const String clipboardAnswer = 'clipboard.answer';
  static const String clipboardReject = 'clipboard.reject';
  static const String clipboardRequest = 'clipboard.request';
  static const String clipboardResponse = 'clipboard.response';

  /// Initiator → peer: the streamed clipboard blob was received (or not).
  static const String clipboardDone = 'clipboard.done';

  const RelayPayloadType._();
}

/// How clipboard bytes travel after the handshake.
class ClipboardDelivery {
  /// Small payload embedded in [ClipboardResponse.clipboardData] (P1).
  static const String inline = 'inline';

  /// Bulk bytes on a relay data stream (P2).
  static const String stream = 'stream';

  const ClipboardDelivery._();
}

/// Encodes an application message for transport inside an envelope.
String encodeRelayPayload(Map<String, dynamic> payload) {
  return base64Encode(utf8.encode(jsonEncode(payload)));
}

/// Decodes a payload, returning null when it is not usable JSON.
Map<String, dynamic>? decodeRelayPayload(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(utf8.decode(base64Decode(encoded)));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final type = decoded['type'];
    if (type is! String || type.isEmpty) {
      return null;
    }
    return decoded;
  } catch (_) {
    return null;
  }
}

/// Sender to receiver: the opening half of the session handshake.
///
/// Readable by the relay, and deliberately so: at this point there are no keys
/// yet. It carries an ephemeral X25519 public key and a nonce, neither of
/// which says anything about the user or the files.
class TransferOffer {
  final String sessionId;

  /// Base64 32-byte ephemeral X25519 public key.
  final String ephemeralPublicKey;

  /// Base64 16 random bytes, mixed into the transcript so neither side can
  /// pin it down on its own.
  final String nonce;

  const TransferOffer({
    required this.sessionId,
    required this.ephemeralPublicKey,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.transferOffer,
    'sid': sessionId,
    'epk': ephemeralPublicKey,
    'n': nonce,
  };

  static TransferOffer? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    final epk = json['epk'];
    final nonce = json['n'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (epk is! String || epk.isEmpty) return null;
    if (nonce is! String || nonce.isEmpty) return null;

    return TransferOffer(
      sessionId: sessionId,
      ephemeralPublicKey: epk,
      nonce: nonce,
    );
  }
}

/// Receiver to sender: the closing half of the handshake.
///
/// [signature] covers the transcript of both halves, which is what turns an
/// anonymous key agreement into one with a known peer on the other end.
class TransferAnswer {
  final String sessionId;
  final String ephemeralPublicKey;
  final String nonce;

  /// Base64 Ed25519 signature over `"R" ‖ transcript`.
  final String signature;

  const TransferAnswer({
    required this.sessionId,
    required this.ephemeralPublicKey,
    required this.nonce,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.transferAnswer,
    'sid': sessionId,
    'epk': ephemeralPublicKey,
    'n': nonce,
    'sig': signature,
  };

  static TransferAnswer? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    final epk = json['epk'];
    final nonce = json['n'];
    final signature = json['sig'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (epk is! String || epk.isEmpty) return null;
    if (nonce is! String || nonce.isEmpty) return null;
    if (signature is! String || signature.isEmpty) return null;

    return TransferAnswer(
      sessionId: sessionId,
      ephemeralPublicKey: epk,
      nonce: nonce,
      signature: signature,
    );
  }
}

/// One file offered in a [TransferManifest].
class ManifestFile {
  final String fileId;
  final String name;
  final int size;

  const ManifestFile({
    required this.fileId,
    required this.name,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'name': name,
    'size': size,
  };

  static ManifestFile? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final fileId = json['fileId'];
    final name = json['name'];
    final size = json['size'];
    if (fileId is! String || fileId.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (size is! int || size < 0) return null;

    return ManifestFile(fileId: fileId, name: name, size: size);
  }
}

/// Sender to receiver: what is about to be sent.
///
/// This is the relay equivalent of the LAN `/batch-confirm-receive` request.
/// It is the first message the receiver can attribute to a device: [signature]
/// covers the handshake transcript, so verifying it against the paired public
/// key proves who derived the session keys.
class TransferManifest {
  final String sessionId;
  final String senderDeviceName;
  final List<ManifestFile> files;

  /// Base64 Ed25519 signature over `"S" ‖ transcript`.
  final String signature;

  const TransferManifest({
    required this.sessionId,
    required this.senderDeviceName,
    required this.files,
    this.signature = '',
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.transferManifest,
    'sid': sessionId,
    'senderDeviceName': senderDeviceName,
    'files': files.map((f) => f.toJson()).toList(),
    'sig': signature,
  };

  static TransferManifest? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    if (sessionId is! String || sessionId.isEmpty) {
      return null;
    }

    final rawFiles = json['files'];
    if (rawFiles is! List || rawFiles.isEmpty) {
      return null;
    }

    final files = <ManifestFile>[];
    for (final entry in rawFiles) {
      final file = ManifestFile.tryParse(entry);
      // One malformed entry invalidates the whole manifest: silently dropping
      // a file would let the user accept a transfer that is not what they saw.
      if (file == null) {
        return null;
      }
      files.add(file);
    }

    final name = json['senderDeviceName'];
    final signature = json['sig'];
    return TransferManifest(
      sessionId: sessionId,
      senderDeviceName: name is String ? name : '',
      files: files,
      signature: signature is String ? signature : '',
    );
  }
}

/// One file the receiver is willing to take, and where it already is.
///
/// [resumeFromChunk] is a claim, not an instruction: the sender checks it
/// against its own copy before honouring it, because a file that changed since
/// the interrupted attempt would otherwise be stitched together from two
/// different versions.
class AcceptedFile {
  final String fileId;

  /// Chunks the receiver already holds and has verified.
  final int resumeFromChunk;

  /// Base64 SHA-256 of the plaintext of chunk `resumeFromChunk - 1`.
  ///
  /// The AEAD tag cannot serve here: resuming re-runs the handshake, so the
  /// same plaintext encrypts to a different tag under the new session keys.
  final String? lastChunkHash;

  const AcceptedFile({
    required this.fileId,
    this.resumeFromChunk = 0,
    this.lastChunkHash,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'resumeFromChunk': resumeFromChunk,
    'lastChunkHash': ?lastChunkHash,
  };

  static AcceptedFile? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final fileId = json['fileId'];
    if (fileId is! String || fileId.isEmpty) {
      return null;
    }

    final resume = json['resumeFromChunk'];
    final hash = json['lastChunkHash'];
    return AcceptedFile(
      fileId: fileId,
      // A malformed offset is treated as "start over" rather than rejected:
      // the worst it costs is a retransmission.
      resumeFromChunk: resume is int && resume > 0 ? resume : 0,
      lastChunkHash: hash is String && hash.isNotEmpty ? hash : null,
    );
  }
}

/// Receiver to sender: the answer to a manifest.
class TransferAccept {
  final String sessionId;
  final bool accepted;
  final String receiverDeviceName;

  /// The files the receiver will take, a subset of the manifest.
  final List<AcceptedFile> files;

  final String? reason;

  const TransferAccept({
    required this.sessionId,
    required this.accepted,
    this.receiverDeviceName = '',
    this.files = const [],
    this.reason,
  });

  List<String> get fileIds => [for (final file in files) file.fileId];

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.transferAccept,
    'sid': sessionId,
    'accepted': accepted,
    'receiverDeviceName': receiverDeviceName,
    'files': [for (final file in files) file.toJson()],
    'reason': ?reason,
  };

  static TransferAccept? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    if (sessionId is! String || sessionId.isEmpty) {
      return null;
    }

    final files = <AcceptedFile>[];
    final rawFiles = json['files'];
    if (rawFiles is List) {
      for (final entry in rawFiles) {
        final file = AcceptedFile.tryParse(entry);
        if (file != null) {
          files.add(file);
        }
      }
    }

    final name = json['receiverDeviceName'];
    final reason = json['reason'];
    return TransferAccept(
      sessionId: sessionId,
      accepted: json['accepted'] == true,
      receiverDeviceName: name is String ? name : '',
      files: files,
      reason: reason is String && reason.isNotEmpty ? reason : null,
    );
  }
}

/// Sender to receiver: pick up this file on this stream.
///
/// [chunkCount] is what makes truncation detectable: the receiver knows how
/// many frames to expect before the first byte arrives, so a relay cutting the
/// stream short cannot pass a partial file off as a complete one.
class FileBegin {
  final String sessionId;
  final String fileId;
  final String streamId;
  final int size;
  final int chunkCount;

  /// First chunk on the wire. The sender's ruling, not the receiver's request:
  /// the receiver asked in `transfer.accept` and may be told to start over.
  final int startChunk;

  /// Which try this is, counting from zero within the session.
  ///
  /// Part of the file key derivation, so both ends have to agree on it. A
  /// retry re-sends chunks under their original numbers, and the number is
  /// what the nonce is built from; a new key per attempt is what keeps that
  /// from being a nonce reused under two different plaintexts.
  final int attempt;

  const FileBegin({
    required this.sessionId,
    required this.fileId,
    required this.streamId,
    required this.size,
    required this.chunkCount,
    this.startChunk = 0,
    this.attempt = 0,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.fileBegin,
    'sid': sessionId,
    'fileId': fileId,
    'streamId': streamId,
    'size': size,
    'chunkSize': AppConstants.relayChunkSize,
    'chunkCount': chunkCount,
    'startChunk': startChunk,
    'attempt': attempt,
  };

  static FileBegin? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    final fileId = json['fileId'];
    final streamId = json['streamId'];
    final size = json['size'];
    final chunkCount = json['chunkCount'];

    if (sessionId is! String || sessionId.isEmpty) return null;
    if (fileId is! String || fileId.isEmpty) return null;
    if (streamId is! String || streamId.isEmpty) return null;
    if (size is! int || size < 0) return null;
    if (chunkCount is! int || chunkCount <= 0) return null;

    // The final chunk always travels, whatever the receiver already has: its
    // frame is the only thing that proves the stream ended where the sender
    // meant it to, so a resume that skipped it would be unverifiable.
    final startChunk = json['startChunk'];
    if (startChunk is! int || startChunk < 0 || startChunk >= chunkCount) {
      return null;
    }

    final attempt = json['attempt'];
    if (attempt is! int || attempt < 0) {
      return null;
    }

    return FileBegin(
      sessionId: sessionId,
      fileId: fileId,
      streamId: streamId,
      size: size,
      chunkCount: chunkCount,
      startChunk: startChunk,
      attempt: attempt,
    );
  }

  /// Frames a file of [size] bytes takes.
  ///
  /// An empty file still gets one frame: the final-chunk flag is what proves
  /// the stream ended where the sender meant it to, and a file with no frames
  /// at all would have nothing to carry that proof.
  static int chunkCountFor(int size) {
    if (size <= 0) {
      return 1;
    }
    return (size + AppConstants.relayChunkSize - 1) ~/
        AppConstants.relayChunkSize;
  }
}

/// Receiver to sender: how that file turned out.
///
/// The upload returning 200 only proves the relay accepted the bytes. Whether
/// they reached the disk is something only the receiver knows, so the sender
/// waits for this before calling a file done.
class FileDone {
  final String sessionId;
  final String fileId;
  final bool ok;
  final int bytes;

  /// Where a failed attempt may pick up, when the receiver kept what it got.
  ///
  /// Null means start over. Only meaningful when [ok] is false; it is what
  /// turns a dropped stream into a retry instead of a lost file.
  final int? resumeFromChunk;

  final String? error;

  const FileDone({
    required this.sessionId,
    required this.fileId,
    required this.ok,
    required this.bytes,
    this.resumeFromChunk,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.fileDone,
    'sid': sessionId,
    'fileId': fileId,
    'ok': ok,
    'bytes': bytes,
    'resumeFromChunk': ?resumeFromChunk,
    'error': ?error,
  };

  static FileDone? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    final fileId = json['fileId'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (fileId is! String || fileId.isEmpty) return null;

    final bytes = json['bytes'];
    final resume = json['resumeFromChunk'];
    final error = json['error'];
    return FileDone(
      sessionId: sessionId,
      fileId: fileId,
      ok: json['ok'] == true,
      bytes: bytes is int ? bytes : 0,
      resumeFromChunk: resume is int && resume > 0 ? resume : null,
      error: error is String && error.isNotEmpty ? error : null,
    );
  }
}

/// Either side: abandon this session.
class TransferCancel {
  final String sessionId;
  final String reason;

  const TransferCancel({required this.sessionId, required this.reason});

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.transferCancel,
    'sid': sessionId,
    'reason': reason,
  };

  static TransferCancel? tryParse(Map<String, dynamic> json) {
    final sessionId = json['sid'];
    if (sessionId is! String || sessionId.isEmpty) {
      return null;
    }
    final reason = json['reason'];
    return TransferCancel(
      sessionId: sessionId,
      reason: reason is String ? reason : '',
    );
  }
}

// ---------------------------------------------------------------------------
// Pairing over the relay (method B)
//
// These are the only application messages sent in the clear, because two
// devices that have never met have no key to encrypt with. They carry public
// keys and device names — nothing that is not already published on the LAN by
// `/health`. What protects them is the code the users read to each other: a
// relay that swaps a public key changes the digits on one screen.
// ---------------------------------------------------------------------------

/// Initiator to peer: this is who I am, may we pair?
class PairRequest {
  final String publicKey;
  final String deviceName;
  final String platform;

  const PairRequest({
    required this.publicKey,
    required this.deviceName,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.pairRequest,
    'pk': publicKey,
    'deviceName': deviceName,
    'platform': platform,
  };

  static PairRequest? tryParse(Map<String, dynamic> json) {
    final publicKey = json['pk'];
    if (publicKey is! String || publicKey.isEmpty) {
      return null;
    }
    final deviceName = json['deviceName'];
    final platform = json['platform'];
    return PairRequest(
      publicKey: publicKey,
      deviceName: deviceName is String ? deviceName : '',
      platform: platform is String ? platform : '',
    );
  }
}

/// Peer to initiator: here is my public key, before either user has agreed.
///
/// The digits need both keys. Sending this as soon as the request is accepted
/// for display lets both screens light up together; [PairResponse] is still
/// what commits the peer's comparison.
class PairAnnounce {
  final String publicKey;
  final String deviceName;
  final String platform;

  const PairAnnounce({
    required this.publicKey,
    required this.deviceName,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.pairAnnounce,
    'pk': publicKey,
    'deviceName': deviceName,
    'platform': platform,
  };

  static PairAnnounce? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.pairAnnounce) {
      return null;
    }
    final publicKey = json['pk'];
    if (publicKey is! String || publicKey.isEmpty) {
      return null;
    }
    final deviceName = json['deviceName'];
    final platform = json['platform'];
    return PairAnnounce(
      publicKey: publicKey,
      deviceName: deviceName is String ? deviceName : '',
      platform: platform is String ? platform : '',
    );
  }
}

/// Peer to initiator: the answer, once its user has compared the digits.
class PairResponse {
  final bool accepted;
  final String publicKey;
  final String deviceName;
  final String platform;

  /// Why it was turned down, when it was.
  final String? reason;

  const PairResponse({
    required this.accepted,
    this.publicKey = '',
    this.deviceName = '',
    this.platform = '',
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.pairResponse,
    'accepted': accepted,
    'pk': publicKey,
    'deviceName': deviceName,
    'platform': platform,
    'reason': ?reason,
  };

  static PairResponse? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.pairResponse) {
      return null;
    }
    final publicKey = json['pk'];
    final deviceName = json['deviceName'];
    final platform = json['platform'];
    final reason = json['reason'];
    return PairResponse(
      accepted: json['accepted'] == true,
      publicKey: publicKey is String ? publicKey : '',
      deviceName: deviceName is String ? deviceName : '',
      platform: platform is String ? platform : '',
      reason: reason is String && reason.isNotEmpty ? reason : null,
    );
  }
}

/// Initiator to peer: both users agreed, commit it.
///
/// Not in the original sketch of method B, which had both sides write their
/// trust entry as soon as the response was sent. That leaves the peer trusting
/// a device whose user went on to see different digits and cancel, so this
/// mirrors the two-step commit LAN pairing already uses.
class PairConfirm {
  final bool accepted;

  const PairConfirm({required this.accepted});

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.pairConfirm,
    'accepted': accepted,
  };

  static PairConfirm? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.pairConfirm) {
      return null;
    }
    return PairConfirm(accepted: json['accepted'] == true);
  }
}

// ---------------------------------------------------------------------------
// Clipboard sync over the relay (P1: small payloads on the signaling plane)
// ---------------------------------------------------------------------------

/// Reasons a peer turns down a clipboard share.
class ClipboardRejectReason {
  static const String notPaired = 'not_paired';
  static const String noUi = 'no_ui';
  static const String busy = 'busy';
  static const String declined = 'declined';
  static const String empty = 'empty';
  static const String tooLarge = 'too_large';
  static const String timeout = 'timeout';

  const ClipboardRejectReason._();
}

/// Initiator → peer: open a clipboard session (same shape as [TransferOffer]).
class ClipboardOffer {
  final String sessionId;
  final String ephemeralPublicKey;
  final String nonce;

  const ClipboardOffer({
    required this.sessionId,
    required this.ephemeralPublicKey,
    required this.nonce,
  });

  /// Shape expected by [RelayCrypto.answerOffer] / [RelayCrypto.completeOffer].
  TransferOffer get asTransferOffer => TransferOffer(
    sessionId: sessionId,
    ephemeralPublicKey: ephemeralPublicKey,
    nonce: nonce,
  );

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardOffer,
    'sid': sessionId,
    'epk': ephemeralPublicKey,
    'n': nonce,
  };

  static ClipboardOffer? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardOffer) return null;
    final sessionId = json['sid'];
    final epk = json['epk'];
    final nonce = json['n'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (epk is! String || epk.isEmpty) return null;
    if (nonce is! String || nonce.isEmpty) return null;
    return ClipboardOffer(
      sessionId: sessionId,
      ephemeralPublicKey: epk,
      nonce: nonce,
    );
  }
}

/// Peer → initiator: signed handshake answer.
class ClipboardAnswer {
  final String sessionId;
  final String ephemeralPublicKey;
  final String nonce;
  final String signature;

  const ClipboardAnswer({
    required this.sessionId,
    required this.ephemeralPublicKey,
    required this.nonce,
    required this.signature,
  });

  TransferAnswer get asTransferAnswer => TransferAnswer(
    sessionId: sessionId,
    ephemeralPublicKey: ephemeralPublicKey,
    nonce: nonce,
    signature: signature,
  );

  factory ClipboardAnswer.fromTransferAnswer(TransferAnswer answer) {
    return ClipboardAnswer(
      sessionId: answer.sessionId,
      ephemeralPublicKey: answer.ephemeralPublicKey,
      nonce: answer.nonce,
      signature: answer.signature,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardAnswer,
    'sid': sessionId,
    'epk': ephemeralPublicKey,
    'n': nonce,
    'sig': signature,
  };

  static ClipboardAnswer? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardAnswer) return null;
    final sessionId = json['sid'];
    final epk = json['epk'];
    final nonce = json['n'];
    final sig = json['sig'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (epk is! String || epk.isEmpty) return null;
    if (nonce is! String || nonce.isEmpty) return null;
    if (sig is! String || sig.isEmpty) return null;
    return ClipboardAnswer(
      sessionId: sessionId,
      ephemeralPublicKey: epk,
      nonce: nonce,
      signature: sig,
    );
  }
}

/// Cleartext refusal before (or instead of) a handshake answer.
class ClipboardReject {
  final String sessionId;
  final String reason;

  const ClipboardReject({required this.sessionId, required this.reason});

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardReject,
    'sid': sessionId,
    'reason': reason,
  };

  static ClipboardReject? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardReject) return null;
    final sessionId = json['sid'];
    final reason = json['reason'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    return ClipboardReject(
      sessionId: sessionId,
      reason: reason is String && reason.isNotEmpty
          ? reason
          : ClipboardRejectReason.declined,
    );
  }
}

/// Encrypted: initiator asks the peer to share its clipboard.
class ClipboardRequest {
  final String sessionId;
  final String requesterDeviceName;

  /// Base64 Ed25519 signature over the handshake transcript (sender role).
  final String signature;

  const ClipboardRequest({
    required this.sessionId,
    required this.requesterDeviceName,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardRequest,
    'sid': sessionId,
    'requesterDeviceName': requesterDeviceName,
    'sig': signature,
  };

  static ClipboardRequest? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardRequest) return null;
    final sessionId = json['sid'];
    final name = json['requesterDeviceName'];
    final sig = json['sig'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (sig is! String || sig.isEmpty) return null;
    return ClipboardRequest(
      sessionId: sessionId,
      requesterDeviceName: name is String ? name : '',
      signature: sig,
    );
  }
}

/// Encrypted: peer's decision and either an inline payload or stream metadata.
class ClipboardResponse {
  final String sessionId;
  final bool accepted;
  final String? reason;

  /// [ClipboardDelivery.inline] or [ClipboardDelivery.stream].
  final String delivery;

  /// Present when [delivery] is inline and [accepted] is true.
  final Map<String, dynamic>? clipboardData;

  /// Stable id for [RelaySessionKeys.fileKey] when streaming.
  final String? blobId;
  final String? streamId;
  final int? size;
  final int? chunkCount;

  /// `text` / `file` — same names as [ClipboardDataType].
  final String? clipboardType;
  final String? fileName;
  final String? mimeType;

  const ClipboardResponse({
    required this.sessionId,
    required this.accepted,
    this.reason,
    this.delivery = ClipboardDelivery.inline,
    this.clipboardData,
    this.blobId,
    this.streamId,
    this.size,
    this.chunkCount,
    this.clipboardType,
    this.fileName,
    this.mimeType,
  });

  bool get isStream => delivery == ClipboardDelivery.stream;

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardResponse,
    'sid': sessionId,
    'accepted': accepted,
    'delivery': delivery,
    'reason': ?reason,
    'clipboardData': ?clipboardData,
    'blobId': ?blobId,
    'streamId': ?streamId,
    'size': ?size,
    'chunkCount': ?chunkCount,
    'clipboardType': ?clipboardType,
    'fileName': ?fileName,
    'mimeType': ?mimeType,
  };

  static ClipboardResponse? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardResponse) return null;
    final sessionId = json['sid'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    final reason = json['reason'];
    final data = json['clipboardData'];
    final deliveryRaw = json['delivery'];
    final delivery = deliveryRaw == ClipboardDelivery.stream
        ? ClipboardDelivery.stream
        : ClipboardDelivery.inline;

    final blobId = json['blobId'];
    final streamId = json['streamId'];
    final size = json['size'];
    final chunkCount = json['chunkCount'];
    final clipboardType = json['clipboardType'];
    final fileName = json['fileName'];
    final mimeType = json['mimeType'];

    if (delivery == ClipboardDelivery.stream && json['accepted'] == true) {
      if (blobId is! String || blobId.isEmpty) return null;
      if (streamId is! String || streamId.isEmpty) return null;
      if (size is! int || size < 0) return null;
      if (chunkCount is! int || chunkCount <= 0) return null;
      if (clipboardType is! String || clipboardType.isEmpty) return null;
    }

    return ClipboardResponse(
      sessionId: sessionId,
      accepted: json['accepted'] == true,
      reason: reason is String && reason.isNotEmpty ? reason : null,
      delivery: delivery,
      clipboardData: data is Map<String, dynamic> ? data : null,
      blobId: blobId is String ? blobId : null,
      streamId: streamId is String ? streamId : null,
      size: size is int ? size : null,
      chunkCount: chunkCount is int ? chunkCount : null,
      clipboardType: clipboardType is String ? clipboardType : null,
      fileName: fileName is String ? fileName : null,
      mimeType: mimeType is String ? mimeType : null,
    );
  }
}

/// Encrypted: initiator tells the peer the streamed clipboard landed.
class ClipboardDone {
  final String sessionId;
  final String blobId;
  final bool ok;
  final String? error;

  const ClipboardDone({
    required this.sessionId,
    required this.blobId,
    required this.ok,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'type': RelayPayloadType.clipboardDone,
    'sid': sessionId,
    'blobId': blobId,
    'ok': ok,
    'error': ?error,
  };

  static ClipboardDone? tryParse(Map<String, dynamic> json) {
    if (json['type'] != RelayPayloadType.clipboardDone) return null;
    final sessionId = json['sid'];
    final blobId = json['blobId'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    if (blobId is! String || blobId.isEmpty) return null;
    final error = json['error'];
    return ClipboardDone(
      sessionId: sessionId,
      blobId: blobId,
      ok: json['ok'] == true,
      error: error is String && error.isNotEmpty ? error : null,
    );
  }
}

