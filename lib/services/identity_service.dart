import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../utils/constants.dart';
import '../utils/log_util.dart';
import '../utils/platform_util.dart';

/// This device's long-lived Ed25519 identity.
///
/// The key pair is generated once and kept in `identity.key` in the
/// application support directory. `deviceId` is derived from the public key so
/// a peer can always check that an announced id really belongs to the key that
/// signs for it.
///
/// The private key is stored in the clear, which is the deliberate trade-off
/// recorded as decision D8 in `docs/relay-design.md`: an attacker who can read
/// the user's files has already compromised the device, and encrypting the key
/// would only move the problem to wherever the decryption key lives.
class IdentityService {
  static final IdentityService instance = IdentityService._();

  IdentityService._() : _overrideFilePath = null;

  /// Test seam; also lets a fresh instance be used in unit tests.
  IdentityService.forTesting({String? filePath}) : _overrideFilePath = filePath;

  static final Ed25519 _signatureAlgorithm = Ed25519();
  static final Sha256 _sha256 = Sha256();

  static const int _seedLength = 32;
  static const int _deviceIdBytes = 16;
  static const int _storageVersion = 1;

  final String? _overrideFilePath;

  final String logTag = LogTags.pairing;

  SimpleKeyPair? _keyPair;
  String? _deviceId;
  String? _publicKeyBase64;
  Uint8List? _publicKeyBytes;
  Future<void>? _initialization;

  /// Loads the key pair from disk, generating one on first run.
  ///
  /// Concurrent callers share a single initialization, so the key is never
  /// generated twice.
  Future<void> ensureInitialized() {
    return _initialization ??= _initialize().catchError((Object error) {
      // Let the next caller retry instead of caching the failure forever.
      _initialization = null;
      throw error;
    });
  }

  Future<String> getDeviceId() async {
    await ensureInitialized();
    return _deviceId!;
  }

  /// Base64-encoded 32-byte Ed25519 public key.
  Future<String> getPublicKeyBase64() async {
    await ensureInitialized();
    return _publicKeyBase64!;
  }

  Future<Uint8List> getPublicKeyBytes() async {
    await ensureInitialized();
    return _publicKeyBytes!;
  }

  /// Cached device id, or null before [ensureInitialized] has completed.
  ///
  /// Callers on hot paths (multicast announcements) use this to stay
  /// synchronous and simply skip the field until the identity is ready.
  String? get deviceIdOrNull => _deviceId;

  String? get publicKeyBase64OrNull => _publicKeyBase64;

  Future<Uint8List> sign(List<int> message) async {
    await ensureInitialized();
    final signature = await _signatureAlgorithm.sign(
      message,
      keyPair: _keyPair!,
    );
    return Uint8List.fromList(signature.bytes);
  }

  /// Verifies [signature] over [message] against a raw 32-byte [publicKey].
  ///
  /// Returns false rather than throwing on malformed input, because every
  /// caller is validating untrusted data from the network.
  static Future<bool> verify(
    List<int> message, {
    required List<int> signature,
    required List<int> publicKey,
  }) async {
    try {
      return await _signatureAlgorithm.verify(
        message,
        signature: Signature(
          signature,
          publicKey: SimplePublicKey(
            publicKey,
            type: KeyPairType.ed25519,
          ),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// `deviceId` is the first 16 bytes of SHA-256 over the public key, in hex.
  static Future<String> deviceIdFromPublicKey(List<int> publicKey) async {
    final digest = await _sha256.hash(publicKey);
    return digest.bytes
        .take(_deviceIdBytes)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Decodes a base64 public key, returning null when it is not a valid
  /// 32-byte Ed25519 key.
  static Uint8List? decodePublicKey(String? base64Key) {
    if (base64Key == null || base64Key.isEmpty) {
      return null;
    }
    try {
      final bytes = base64Decode(base64Key);
      if (bytes.length != _seedLength) {
        return null;
      }
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Checks that [deviceId] really is the fingerprint of [publicKey].
  ///
  /// This is what stops a peer from announcing somebody else's device id.
  static Future<bool> matchesDeviceId(String deviceId, List<int> publicKey) async {
    final derived = await deviceIdFromPublicKey(publicKey);
    return derived == deviceId;
  }

  Future<void> _initialize() async {
    final filePath =
        _overrideFilePath ??
        await PlatformUtil.getAppSupportFilePath(AppConstants.identityFileName);
    final file = File(filePath);

    Uint8List? seed = await _readSeed(file);
    if (seed == null) {
      seed = await _generateSeed();
      await _writeSeed(file, seed);
      LogUtil.iTag(logTag, '生成新的设备身份密钥: ${file.path}');
    }

    final keyPair = await _signatureAlgorithm.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = Uint8List.fromList(publicKey.bytes);

    _keyPair = keyPair;
    _publicKeyBytes = publicKeyBytes;
    _publicKeyBase64 = base64Encode(publicKeyBytes);
    _deviceId = await deviceIdFromPublicKey(publicKeyBytes);

    LogUtil.iTag(logTag, '设备身份就绪: deviceId=$_deviceId');
  }

  Future<Uint8List> _generateSeed() async {
    final keyPair = await _signatureAlgorithm.newKeyPair();
    final seed = await keyPair.extractPrivateKeyBytes();
    return Uint8List.fromList(seed);
  }

  Future<Uint8List?> _readSeed(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final seed = base64Decode(json['seed'] as String);
      if (seed.length != _seedLength) {
        LogUtil.wTag(logTag, '身份密钥长度异常，将重新生成');
        return null;
      }
      return Uint8List.fromList(seed);
    } catch (e) {
      LogUtil.wTag(logTag, '读取身份密钥失败，将重新生成: $e');
      return null;
    }
  }

  Future<void> _writeSeed(File file, Uint8List seed) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'v': _storageVersion,
        'alg': 'ed25519',
        'seed': base64Encode(seed),
      }),
      flush: true,
    );
    await _restrictPermissions(file);
  }

  /// `dart:io` has no chmod, so POSIX platforms shell out.
  ///
  /// Windows is left alone: files under `%APPDATA%` already inherit an ACL
  /// that grants access to the current user only.
  Future<void> _restrictPermissions(File file) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      final result = await Process.run('chmod', ['600', file.path]);
      if (result.exitCode != 0) {
        LogUtil.wTag(logTag, 'chmod 600 失败: ${result.stderr}');
      }
    } catch (e) {
      LogUtil.wTag(logTag, '无法设置身份密钥文件权限: $e');
    }
  }
}
