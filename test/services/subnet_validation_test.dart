import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/validation_service.dart';

void main() {
  group('Subnet Validation Tests', () {
    final validationService = ValidationService();

    test('validateIPv4 - valid IP addresses', () {
      expect(validationService.validateIPv4('192.168.1.1').isValid, true);
      expect(validationService.validateIPv4('10.0.0.1').isValid, true);
      expect(validationService.validateIPv4('172.16.0.1').isValid, true);
      expect(validationService.validateIPv4('255.255.255.255').isValid, true);
    });

    test('validateIPv4 - invalid IP addresses', () {
      expect(validationService.validateIPv4('').isValid, false);
      expect(validationService.validateIPv4('256.1.1.1').isValid, false);
      expect(validationService.validateIPv4('192.168.1').isValid, false);
      expect(validationService.validateIPv4('abc.def.ghi.jkl').isValid, false);
      expect(validationService.validateIPv4('192.168.1.1.1').isValid, false);
    });

    test('validateIPv4WithSubnet - format validation', () {
      // Invalid format should fail immediately
      final result1 = validationService.validateIPv4WithSubnet('');
      expect(result1.isValid, false);

      final result2 = validationService.validateIPv4WithSubnet('256.1.1.1');
      expect(result2.isValid, false);

      final result3 = validationService.validateIPv4WithSubnet('192.168.1');
      expect(result3.isValid, false);
    });

    test('validateIPv4WithSubnet - no server address provided', () {
      // Should pass if no server address provided (skip subnet check)
      final result = validationService.validateIPv4WithSubnet('192.168.1.100');
      expect(result.isValid, true);
    });

    test('validateIPv4WithSubnet - same subnet', () {
      // Same subnet should pass
      final result = validationService.validateIPv4WithSubnet(
        '192.168.1.100',
        serverAddress: '192.168.1.10:8080',
      );
      expect(result.isValid, true);
    });

    test('validateIPv4WithSubnet - different subnet', () {
      // Different subnet should fail with warning
      final result = validationService.validateIPv4WithSubnet(
        '192.168.2.100',
        serverAddress: '192.168.1.10:8080',
      );
      expect(result.isValid, false);
      expect(result.isWarning, true);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.contains('网段不匹配'), true);
    });

    test('validateIPv4WithSubnet - completely different network', () {
      // Completely different network should fail with warning
      final result = validationService.validateIPv4WithSubnet(
        '10.0.0.100',
        serverAddress: '192.168.1.10:8080',
      );
      expect(result.isValid, false);
      expect(result.isWarning, true);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.contains('网段不匹配'), true);
    });

    test('validateIPv4WithSubnet - invalid server address format', () {
      // Invalid server address should skip subnet check
      final result = validationService.validateIPv4WithSubnet(
        '192.168.1.100',
        serverAddress: 'invalid',
      );
      expect(result.isValid, true);
    });

    test('validateIPv4WithSubnet - extract IP from server address', () {
      // Test various server address formats
      final result1 = validationService.validateIPv4WithSubnet(
        '192.168.1.100',
        serverAddress: '192.168.1.10:8080',
      );
      expect(result1.isValid, true);

      final result2 = validationService.validateIPv4WithSubnet(
        '192.168.1.100',
        serverAddress: '192.168.1.10:9999',
      );
      expect(result2.isValid, true);
    });
  });
}
