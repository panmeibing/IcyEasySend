import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  group('RelayEnvelope', () {
    test('stamps the protocol version on outbound messages', () {
      final message = RelayEnvelope.build(
        RelayMessageType.streamCreate,
        mid: 'm1',
        fields: {'peer': 'abc', 'role': RelayStreamRole.sender},
      );

      expect(message['v'], relayProtocolVersion);
      expect(message['type'], 'stream.create');
      expect(message['mid'], 'm1');
      expect(message['peer'], 'abc');
    });

    test('omits the message id when there is nothing to correlate', () {
      final message = RelayEnvelope.build(RelayMessageType.ping);
      expect(message.containsKey('mid'), isFalse);
    });

    test('decodes a server message', () {
      final envelope = RelayEnvelope.decode(
        jsonEncode({'v': 1, 'type': 'welcome', 'sessionId': 'abc'}),
      );

      expect(envelope, isNotNull);
      expect(envelope!.type, 'welcome');
      expect(envelope.sessionId, 'abc');
    });

    test('drops frames that are not usable messages', () {
      // Everything arriving on the socket is untrusted, so nothing here may
      // throw: a malformed frame must be ignored, not crash the connection.
      expect(RelayEnvelope.decode('not json'), isNull);
      expect(RelayEnvelope.decode('[]'), isNull);
      expect(RelayEnvelope.decode('{"v":1}'), isNull);
      expect(RelayEnvelope.decode('{"v":1,"type":""}'), isNull);
      expect(RelayEnvelope.decode('{"v":1,"type":42}'), isNull);
    });
  });

  group('payload envelope', () {
    test('round-trips an application message through base64', () {
      const manifest = TransferManifest(
        sessionId: 'sid',
        senderDeviceName: 'Laptop',
        files: [ManifestFile(fileId: 'f1', name: 'a.txt', size: 12)],
      );

      final decoded = decodeRelayPayload(
        encodeRelayPayload(manifest.toJson()),
      );

      expect(decoded, isNotNull);
      expect(decoded!['type'], RelayPayloadType.transferManifest);
      expect(TransferManifest.tryParse(decoded)!.files.single.name, 'a.txt');
    });

    test('drops payloads that are not usable', () {
      expect(decodeRelayPayload(null), isNull);
      expect(decodeRelayPayload(''), isNull);
      expect(decodeRelayPayload('not base64!!'), isNull);
      expect(decodeRelayPayload(base64Encode(utf8.encode('{}'))), isNull);
      expect(decodeRelayPayload(base64Encode(utf8.encode('[]'))), isNull);
    });
  });

  group('TransferManifest', () {
    test('parses a well-formed manifest', () {
      final manifest = TransferManifest.tryParse({
        'type': RelayPayloadType.transferManifest,
        'sid': 'sid',
        'senderDeviceName': 'Laptop',
        'files': [
          {'fileId': 'f1', 'name': 'a.txt', 'size': 1},
          {'fileId': 'f2', 'name': 'b/c.txt', 'size': 0},
        ],
      });

      expect(manifest, isNotNull);
      expect(manifest!.files, hasLength(2));
      expect(manifest.files[1].name, 'b/c.txt');
    });

    test('rejects the whole manifest when one file is malformed', () {
      // Dropping the bad entry would show the user a confirmation dialog that
      // does not match what the sender is about to send.
      final manifest = TransferManifest.tryParse({
        'sid': 'sid',
        'files': [
          {'fileId': 'f1', 'name': 'a.txt', 'size': 1},
          {'fileId': 'f2', 'name': 'b.txt'},
        ],
      });

      expect(manifest, isNull);
    });

    test('rejects a manifest with no session or no files', () {
      expect(
        TransferManifest.tryParse({
          'files': [
            {'fileId': 'f1', 'name': 'a.txt', 'size': 1},
          ],
        }),
        isNull,
      );
      expect(TransferManifest.tryParse({'sid': 'sid', 'files': []}), isNull);
    });

    test('rejects a negative file size', () {
      expect(
        ManifestFile.tryParse({'fileId': 'f', 'name': 'a', 'size': -1}),
        isNull,
      );
    });
  });

  group('TransferAccept', () {
    test('round-trips an acceptance with its file list', () {
      const accept = TransferAccept(
        sessionId: 'sid',
        accepted: true,
        receiverDeviceName: 'Phone',
        files: [AcceptedFile(fileId: 'f1'), AcceptedFile(fileId: 'f2')],
      );

      final parsed = TransferAccept.tryParse(accept.toJson());
      expect(parsed!.accepted, isTrue);
      expect(parsed.fileIds, ['f1', 'f2']);
      expect(parsed.receiverDeviceName, 'Phone');
    });

    test('round-trips a resume offer', () {
      const accept = TransferAccept(
        sessionId: 'sid',
        accepted: true,
        files: [
          AcceptedFile(
            fileId: 'f1',
            resumeFromChunk: 7,
            lastChunkHash: 'aGFzaA==',
          ),
        ],
      );

      final parsed = TransferAccept.tryParse(accept.toJson());
      expect(parsed!.files.single.resumeFromChunk, 7);
      expect(parsed.files.single.lastChunkHash, 'aGFzaA==');
    });

    test('treats a file with no resume offer as starting over', () {
      final parsed = TransferAccept.tryParse({
        'sid': 'sid',
        'accepted': true,
        'files': [
          {'fileId': 'f1'},
        ],
      });

      expect(parsed!.files.single.resumeFromChunk, 0);
      expect(parsed.files.single.lastChunkHash, isNull);
    });

    test('ignores a negative resume offer rather than rejecting the accept', () {
      final parsed = TransferAccept.tryParse({
        'sid': 'sid',
        'accepted': true,
        'files': [
          {'fileId': 'f1', 'resumeFromChunk': -3},
        ],
      });

      expect(parsed!.files.single.resumeFromChunk, 0);
    });

    test('round-trips a rejection with its reason', () {
      const accept = TransferAccept(
        sessionId: 'sid',
        accepted: false,
        reason: 'not_paired',
      );

      final parsed = TransferAccept.tryParse(accept.toJson());
      expect(parsed!.accepted, isFalse);
      expect(parsed.reason, 'not_paired');
    });

    test('treats a missing accepted flag as a rejection', () {
      final parsed = TransferAccept.tryParse({'sid': 'sid'});
      expect(parsed!.accepted, isFalse);
    });
  });

  group('FileBegin and FileDone', () {
    test('round-trip', () {
      final streamId = 'a' * 64;
      final begin = FileBegin(
        sessionId: 'sid',
        fileId: 'f1',
        streamId: streamId,
        size: 4096,
        chunkCount: 1,
      );
      final parsedBegin = FileBegin.tryParse(begin.toJson());
      expect(parsedBegin!.streamId, streamId);
      expect(parsedBegin.size, 4096);
      expect(parsedBegin.chunkCount, 1);
      expect(parsedBegin.startChunk, 0);

      const done = FileDone(
        sessionId: 'sid',
        fileId: 'f1',
        ok: true,
        bytes: 4096,
      );
      final parsedDone = FileDone.tryParse(done.toJson());
      expect(parsedDone!.ok, isTrue);
      expect(parsedDone.bytes, 4096);
      expect(parsedDone.error, isNull);
      expect(parsedDone.resumeFromChunk, isNull);
    });

    test('round-trips a resumed file.begin', () {
      final begin = FileBegin(
        sessionId: 'sid',
        fileId: 'f1',
        streamId: 'a' * 64,
        size: 4096 * 10,
        chunkCount: 4,
        startChunk: 2,
        attempt: 1,
      );

      final parsed = FileBegin.tryParse(begin.toJson());
      expect(parsed!.startChunk, 2);
      // The attempt selects the file key, so a receiver left to guess it would
      // decrypt nothing at all. It has to travel.
      expect(parsed.attempt, 1);
    });

    test('rejects a start chunk at or past the end of the file', () {
      Map<String, dynamic> beginWith(int startChunk) => {
        'sid': 'sid',
        'fileId': 'f1',
        'streamId': 'a' * 64,
        'size': 4096,
        'chunkCount': 3,
        'startChunk': startChunk,
        'attempt': 0,
      };

      // The final frame carries the proof the stream was not truncated, so a
      // resume that skipped it could never be verified.
      expect(FileBegin.tryParse(beginWith(3)), isNull);
      expect(FileBegin.tryParse(beginWith(-1)), isNull);
      expect(FileBegin.tryParse(beginWith(2))!.startChunk, 2);
    });

    test('carries the resume point of a failed receive', () {
      const done = FileDone(
        sessionId: 'sid',
        fileId: 'f1',
        ok: false,
        bytes: 0,
        resumeFromChunk: 12,
        error: '中转下载失败',
      );

      final parsed = FileDone.tryParse(done.toJson());
      expect(parsed!.ok, isFalse);
      expect(parsed.resumeFromChunk, 12);
      expect(parsed.error, '中转下载失败');
    });

    test('rejects a file.begin without a stream to attach to', () {
      expect(
        FileBegin.tryParse({
          'sid': 'sid',
          'fileId': 'f1',
          'size': 1,
          'chunkCount': 1,
        }),
        isNull,
      );
    });

    test('rejects a file.begin that does not say how many frames to expect',
        () {
      // Without the count there is nothing to check a short stream against,
      // so a file.begin missing it is not usable.
      expect(
        FileBegin.tryParse({
          'sid': 'sid',
          'fileId': 'f1',
          'streamId': 'a' * 64,
          'size': 1,
        }),
        isNull,
      );
    });

    test('an empty file is still one frame', () {
      expect(FileBegin.chunkCountFor(0), 1);
      expect(FileBegin.chunkCountFor(1), 1);
      expect(FileBegin.chunkCountFor(AppConstants.relayChunkSize), 1);
      expect(FileBegin.chunkCountFor(AppConstants.relayChunkSize + 1), 2);
      expect(FileBegin.chunkCountFor(AppConstants.relayChunkSize * 4), 4);
    });

    test('carries the failure reason back to the sender', () {
      final done = FileDone.tryParse(
        const FileDone(
          sessionId: 'sid',
          fileId: 'f1',
          ok: false,
          bytes: 0,
          error: 'disk full',
        ).toJson(),
      );

      expect(done!.ok, isFalse);
      expect(done.error, 'disk full');
    });
  });

  group('handshake messages', () {
    test('an offer round-trips', () {
      const offer = TransferOffer(
        sessionId: 'sid',
        ephemeralPublicKey: 'ZXBr',
        nonce: 'bm9uY2U=',
      );

      final parsed = TransferOffer.tryParse(offer.toJson());
      expect(parsed!.ephemeralPublicKey, 'ZXBr');
      expect(parsed.nonce, 'bm9uY2U=');
    });

    test('an answer without a signature is not an answer', () {
      expect(
        TransferAnswer.tryParse({
          'sid': 'sid',
          'epk': 'ZXBr',
          'n': 'bm9uY2U=',
        }),
        isNull,
      );
    });

    test('a manifest carries the sender signature', () {
      const manifest = TransferManifest(
        sessionId: 'sid',
        senderDeviceName: 'Laptop',
        files: [ManifestFile(fileId: 'f1', name: 'a.txt', size: 1)],
        signature: 'c2ln',
      );

      expect(TransferManifest.tryParse(manifest.toJson())!.signature, 'c2ln');
    });

    test('a manifest from an older peer parses with an empty signature', () {
      // It will fail verification rather than be accepted, but it has to get
      // that far to produce a sensible refusal.
      final parsed = TransferManifest.tryParse({
        'sid': 'sid',
        'files': [
          {'fileId': 'f1', 'name': 'a.txt', 'size': 1},
        ],
      });

      expect(parsed!.signature, isEmpty);
    });
  });

  group('pairing messages', () {
    test('a request round-trips', () {
      const request = PairRequest(
        publicKey: 'cGs=',
        deviceName: 'Laptop',
        platform: 'windows',
      );

      final parsed = PairRequest.tryParse(request.toJson());
      expect(parsed!.publicKey, 'cGs=');
      expect(parsed.deviceName, 'Laptop');
      expect(parsed.platform, 'windows');
    });

    test('a request without a key is rejected', () {
      expect(PairRequest.tryParse({'deviceName': 'Laptop'}), isNull);
    });

    test('a refusal round-trips with its reason', () {
      const response = PairResponse(accepted: false, reason: 'rejected');

      final parsed = PairResponse.tryParse(response.toJson());
      expect(parsed!.accepted, isFalse);
      expect(parsed.reason, 'rejected');
    });

    test('a confirmation is only a confirmation when it says so', () {
      expect(
        PairConfirm.tryParse(const PairConfirm(accepted: true).toJson())!
            .accepted,
        isTrue,
      );
      expect(PairConfirm.tryParse({'type': 'pair.response'}), isNull);
    });
  });
}
