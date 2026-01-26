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
    final ipv4Pattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

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

  /// Validates IPv4 address and checks if it's in the same subnet as local IP
  ///
  /// [ip] - The target IP address to validate
  /// [serverAddress] - The server address in format "IP:Port" (optional)
  ///
  /// Returns a ValidationResult with detailed error message if not in same subnet
  ValidationResult validateIPv4WithSubnet(String ip, {String? serverAddress}) {
    // First validate the IP format
    final formatValidation = validateIPv4(ip);
    if (!formatValidation.isValid) {
      return formatValidation;
    }

    // If no server address provided, skip subnet check
    if (serverAddress == null || serverAddress.isEmpty) {
      return ValidationResult(isValid: true);
    }

    // Extract local IP from server address (format: "IP:Port")
    final localIP = _extractIPFromAddress(serverAddress);
    if (localIP == null) {
      // Cannot determine local IP, skip subnet check
      return ValidationResult(isValid: true);
    }

    // Check if in same subnet (assuming /24 subnet mask: 255.255.255.0)
    if (!_isInSameSubnet(localIP, ip)) {
      return ValidationResult(
        isValid: false,
        errorMessage: ErrorMessages.ipAddressNotInSameSubnet(localIP, ip),
        isWarning: true, // This is a warning, not a hard error
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Extract IP address from server address string (format: "IP:Port")
  String? _extractIPFromAddress(String serverAddress) {
    try {
      final parts = serverAddress.split(':');
      if (parts.isNotEmpty) {
        final ip = parts[0];
        // Validate that the extracted IP is a valid IPv4 format
        final ipValidation = validateIPv4(ip);
        if (ipValidation.isValid) {
          return ip;
        }
      }
    } catch (e) {
      // Failed to parse
      return null;
    }
    return null;
  }

  /// Check if two IP addresses are in the same subnet
  /// Assumes a /24 subnet mask (255.255.255.0)
  bool _isInSameSubnet(String ip1, String ip2) {
    final parts1 = ip1.split('.');
    final parts2 = ip2.split('.');

    if (parts1.length != 4 || parts2.length != 4) {
      return false;
    }

    // Compare first 3 octets (assuming /24 subnet)
    for (int i = 0; i < 3; i++) {
      if (parts1[i] != parts2[i]) {
        return false;
      }
    }

    return true;
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
  final bool isWarning; // True if this is a warning rather than a hard error

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isWarning = false,
  });
}
