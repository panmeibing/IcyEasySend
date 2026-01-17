import 'dart:io';
import '../utils/error_messages.dart';

/// ValidationService provides input validation functionality
class ValidationService {
  /// Validates IPv4 address format
  /// 
  /// Returns a ValidationResult indicating whether the IP is valid
  /// and an error message if invalid
  ValidationResult validateIPv4(String ip) {
    if (ip.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressEmpty,
      );
    }

    // IPv4 format: xxx.xxx.xxx.xxx where xxx is 0-255
    final ipv4Pattern = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    );

    final match = ipv4Pattern.firstMatch(ip);
    if (match == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressInvalidFormat,
      );
    }

    // Validate each octet is in range 0-255
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!);
      if (octet == null || octet < 0 || octet > 255) {
        return ValidationResult(
          isValid: false,
          errorMessage: ErrorMessages.ipAddressInvalidRange,
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  /// Validates if a file exists and is readable
  /// 
  /// Returns a ValidationResult indicating whether the file is valid
  /// and an error message if invalid
  ValidationResult validateFile(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.fileNotFound,
      );
    }

    // Check if file is readable by attempting to get its length
    try {
      // This will throw if the file is not readable
      file.lengthSync();
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.fileNotReadable,
      );
    }
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
