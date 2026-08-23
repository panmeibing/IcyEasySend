import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/multicast_announcement.dart';
import 'package:icy_easy_send/utils/constants.dart';

void main() {
  final publicKey = base64Encode(List<int>.filled(32, 5));

  group('MulticastAnnouncement', () {
    test('carries the identity fields when the key is available', () {
      final announcement = MulticastAnnouncement.forDevice(
        deviceName: 'Desktop',
        deviceId: 'a' * 32,
        port: 9527,
        announcement: true,
        publicKey: publicKey,
      );

      final json = announcement.toJson();
      expect(json['publicKey'], publicKey);
      expect(json['protocolVersion'], AppConstants.protocolVersion);
    });

    test('omits the public key before the identity has loaded', () {
      final json = MulticastAnnouncement.forDevice(
        deviceName: 'Desktop',
        deviceId: 'a' * 32,
        port: 9527,
        announcement: true,
      ).toJson();

      expect(json.containsKey('publicKey'), isFalse);
    });

    test('round trips through the wire format', () {
      final original = MulticastAnnouncement.forDevice(
        deviceName: 'Desktop',
        deviceId: 'a' * 32,
        port: 9527,
        announcement: false,
        publicKey: publicKey,
      );

      final parsed = MulticastAnnouncement.tryParse(original.toBytes());

      expect(parsed, isNotNull);
      expect(parsed!.deviceId, original.deviceId);
      expect(parsed.publicKey, publicKey);
      expect(parsed.protocolVersion, AppConstants.protocolVersion);
      expect(parsed.announcement, isFalse);
    });

    test('still parses an announcement from a pre-identity client', () {
      final legacy = utf8.encode(
        jsonEncode({
          'app': AppConstants.projectNameTight,
          'deviceName': 'Old Phone',
          'version': '1.0.0',
          'deviceId': 'legacy-random-id',
          'port': 9527,
          'announcement': true,
        }),
      );

      final parsed = MulticastAnnouncement.tryParse(legacy);

      expect(parsed, isNotNull);
      expect(parsed!.deviceName, 'Old Phone');
      expect(parsed.publicKey, isNull);
      expect(parsed.protocolVersion, isNull);
    });

    test('ignores fields added by a newer client', () {
      final future = utf8.encode(
        jsonEncode({
          'app': AppConstants.projectNameTight,
          'deviceName': 'Future',
          'deviceId': 'b' * 32,
          'port': 9527,
          'announcement': true,
          'somethingNew': {'nested': true},
        }),
      );

      expect(MulticastAnnouncement.tryParse(future), isNotNull);
    });

    test('ignores payloads from other applications', () {
      final foreign = utf8.encode(
        jsonEncode({
          'app': 'SomeOtherApp',
          'deviceName': 'Nope',
          'deviceId': 'x',
          'port': 9527,
        }),
      );

      expect(MulticastAnnouncement.tryParse(foreign), isNull);
    });
  });
}
