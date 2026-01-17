import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/validation_service.dart';

void main() {
  late ValidationService validationService;

  setUp(() {
    validationService = ValidationService();
  });

  group('IPv4 Validation', () {
    test('validates correct IPv4 addresses', () {
      final validIPs = [
        '192.168.1.1',
        '10.0.0.1',
        '172.16.0.1',
        '8.8.8.8',
        '255.255.255.255',
        '0.0.0.0',
      ];

      for (final ip in validIPs) {
        final result = validationService.validateIPv4(ip);
        expect(result.isValid, true, reason: '$ip should be valid');
        expect(result.errorMessage, isNull);
      }
    });

    test('rejects invalid IPv4 addresses', () {
      final invalidIPs = [
        '256.1.1.1', // octet > 255
        '1.256.1.1',
        '1.1.256.1',
        '1.1.1.256',
        '999.999.999.999',
        'abc.def.ghi.jkl', // non-numeric
        '192.168.1', // missing octet
        '192.168.1.1.1', // too many octets
        '192.168.-1.1', // negative number
        '', // empty string
        '192.168.1.', // trailing dot
        '.192.168.1.1', // leading dot
        '192..168.1.1', // double dot
      ];

      for (final ip in invalidIPs) {
        final result = validationService.validateIPv4(ip);
        expect(result.isValid, false, reason: '$ip should be invalid');
        expect(result.errorMessage, isNotNull);
      }
    });

    test('handles edge cases', () {
      // Empty string
      var result = validationService.validateIPv4('');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('不能为空'));

      // Boundary values
      result = validationService.validateIPv4('0.0.0.0');
      expect(result.isValid, true);

      result = validationService.validateIPv4('255.255.255.255');
      expect(result.isValid, true);

      // Just over boundary
      result = validationService.validateIPv4('255.255.255.256');
      expect(result.isValid, false);
    });
  });

  group('File Validation', () {
    test('validates existing readable file', () {
      // Create a temporary test file
      final tempDir = Directory.systemTemp.createTempSync('validation_test_');
      final testFile = File('${tempDir.path}/test_file.txt');
      testFile.writeAsStringSync('test content');

      final result = validationService.validateFile(testFile);
      expect(result.isValid, true);
      expect(result.errorMessage, isNull);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('rejects non-existent file', () {
      final nonExistentFile = File('/path/that/does/not/exist/file.txt');
      
      final result = validationService.validateFile(nonExistentFile);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('不存在'));
    });

    test('handles various file types', () {
      final tempDir = Directory.systemTemp.createTempSync('validation_test_');
      
      // Test different file types
      final textFile = File('${tempDir.path}/test.txt');
      textFile.writeAsStringSync('text content');
      
      final binaryFile = File('${tempDir.path}/test.bin');
      binaryFile.writeAsBytesSync([0, 1, 2, 3, 4, 5]);
      
      final emptyFile = File('${tempDir.path}/empty.txt');
      emptyFile.writeAsStringSync('');

      expect(validationService.validateFile(textFile).isValid, true);
      expect(validationService.validateFile(binaryFile).isValid, true);
      expect(validationService.validateFile(emptyFile).isValid, true);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });
}
