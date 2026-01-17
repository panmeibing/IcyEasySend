import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/file_transfer_service.dart';

void main() {
  group('FileTransferService', () {
    late FileTransferService service;

    setUp(() {
      service = FileTransferService();
    });

    group('checkHealth', () {
      test('should return error for invalid IP', () async {
        final result = await service.checkHealth('invalid.ip.address');
        
        expect(result.isHealthy, false);
        expect(result.errorMessage, isNotNull);
      });

      test('should return error for unreachable device', () async {
        // Use a non-routable IP address
        final result = await service.checkHealth('192.0.2.1:8080');
        
        expect(result.isHealthy, false);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('连接'));
      });

      test('should handle timeout gracefully', () async {
        // Use an IP that will timeout
        final result = await service.checkHealth('10.255.255.1:8080');
        
        expect(result.isHealthy, false);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('sendFile', () {
      test('should return error for non-existent file', () async {
        final nonExistentFile = File('/path/to/nonexistent/file.txt');
        
        final result = await service.sendFile(
          targetIP: '192.168.1.1:8080',
          file: nonExistentFile,
        );
        
        expect(result.success, false);
        expect(result.errorMessage, contains('文件不存在'));
      });

      test('should perform health check before sending', () async {
        // Create a temporary test file
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_file.txt');
        await testFile.writeAsString('test content');
        
        try {
          // Use unreachable IP to test health check
          final result = await service.sendFile(
            targetIP: '192.0.2.1:8080',
            file: testFile,
          );
          
          expect(result.success, false);
          expect(result.errorMessage, contains('目标设备不可用'));
        } finally {
          // Clean up
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });
  });
}
