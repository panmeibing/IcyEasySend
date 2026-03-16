# Icy Easy Send

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-BSD--3--Clause-green.svg)

An efficient, cross-platform LAN file transfer application

[English](README.md) | [简体中文](README_CN.md)

[Features](#-features) • [Quick Start](#-quick-start) • [Usage](#-usage) • [Architecture](#%EF%B8%8F-architecture) • [Development](#%EF%B8%8F-development-guide)

</div>

---

## 📖 Introduction

Icy Easy Send is a local area network file transfer tool developed based on Flutter, supporting fast and secure file
transfers and clipboard content synchronization between multiple devices within the same local area network. No internet
connection or account registration is required, and it can be used immediately after opening.

### Why Choose Icy Easy Send?

- � **High-Speed Transfer**: Direct LAN connection, transfer speed limited only by network bandwidth
- 🔒 **Secure & Reliable**: Data doesn't go through third-party servers, completely transferred over local network
- � **Cross-Platform**: One codebase supporting Android, iOS, Windows, macOS, and Linux
- 🎯 **Easy to Use**: No complex configuration, just enter IP address to start transferring
- 📦 **Batch Transfer**: Send multiple files at once with automatic queue management
- 📋 **Clipboard Sync**: Synchronize text, files, and images across devices

---

## ✨ Features

### Core Functionality

- **File Transfer**
    - Support for single or batch file transfers
    - Real-time display of transfer progress, speed, and remaining time
    - Automatic handling of filename conflicts
    - Support for large file transfers (up to 20GB)
    - Configurable concurrent transfer count (1-10 files simultaneously)

- **Clipboard Synchronization**
    - Cross-device text content synchronization
    - File URI synchronization support
    - Image format support (PNG, JPEG, BMP)
    - Configurable clipboard size limit (1-10MB)

- **User Experience**
    - Drag and drop file support (desktop platforms)
    - Share files from other apps to this application
    - IP address history
    - Real-time IP address validation
    - Network status monitoring and auto-reconnection

- **Transfer History**
    - Complete transfer history records
    - Filter by type (All/Sent/Received)
    - Transfer statistics
    - Quick open file or folder
    - Configurable history retention count

- **Network Diagnostics**
    - Built-in network diagnostic tools
    - Network connection status detection
    - Port availability testing
    - Target device reachability check

---

## 🚀 Quick Start

### Requirements

- Flutter SDK: 3.41.2 or higher
- Dart SDK: 3.11.0 or higher
- Platform-specific development environment:
    - Android: Android Studio / Android SDK
    - iOS: Xcode (macOS only)
    - Windows: Visual Studio 2022
    - macOS: Xcode
    - Linux: Relevant development toolchain

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd icy_easy_send
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run the application**

```bash
# Android
flutter run -d android

# iOS (macOS required)
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Build Release Version

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS required)
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 📱 Usage

### Basic Workflow

1. **Launch Application**
    - The HTTP server starts automatically when the app launches
    - View your device's IP address and port number at the top of the home page

2. **Send Files**
    - Enter the receiver's IP address in the "Target IP" input field
    - Click the "Select Files" button to choose files (or drag and drop files directly)
    - Click the "Send" button
    - Transfer begins after receiver confirms

3. **Receive Files**
    - Keep the application running
    - A confirmation dialog appears when someone sends you files
    - Review the file list and click "Receive"
    - Files are automatically saved to the downloads folder

4. **Sync Clipboard**
    - Enter the target device's IP address
    - Click the "Sync Remote Clipboard" button on the home page
    - After the other party confirms, their clipboard content syncs to your device

5. **View History**
    - Switch to the "History" tab
    - View all transfer records
    - Filter, open files, or delete records

### Advanced Settings

Configure in the "Settings" page:

- **Device Name**: Customize device name for easy identification by other devices
- **Concurrent Transfers**: Set the number of simultaneous file transfers (1-10)
- **History Count**: Set the number of history records to retain (10-1000)
- **Clipboard Size**: Set maximum clipboard content size (1-10MB)
- **IP Validation**: Enable/disable IP address format validation

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                          # Application entry point
├── models/                            # Data models
│   ├── device_info.dart              # Device information
│   ├── file_transfer_request.dart    # File transfer request
│   ├── transfer_data.dart            # Transfer data
│   ├── transfer_history.dart         # Transfer history
│   └── clipboard_data_model.dart     # Clipboard data
├── pages/                             # UI pages
│   ├── home_page.dart                # Home page
│   ├── history_page.dart             # History page
│   ├── settings_page.dart            # Settings page
│   ├── main_container.dart           # Main container
│   ├── controllers/                  # Page controllers
│   └── widgets/                      # UI components
├── services/                          # Business logic services
│   ├── http_server_manager.dart      # HTTP server management
│   ├── file_transfer_service.dart    # File transfer service
│   ├── clipboard_service.dart        # Clipboard service
│   ├── permission_service.dart       # Permission management
│   ├── preferences_service.dart      # Local storage
│   ├── transfer_history_service.dart # History management
│   └── transfer/                     # Transfer submodule
│       ├── file_sender.dart          # File sender
│       ├── file_receiver.dart        # File receiver
│       ├── batch_transfer_manager.dart # Batch transfer manager
│       └── health_checker.dart       # Health checker
└── utils/                             # Utility functions
    ├── constants.dart                # Constants
    ├── network_util.dart             # Network utilities
    ├── format_util.dart              # Format utilities
    └── log_util.dart                 # Logging utilities
```

### Core Technology Stack

- **UI Framework**: Flutter 3.41.2+
- **HTTP Server**: shelf + shelf_router
- **Network Communication**: http + connectivity_plus
- **File Operations**: file_picker + path_provider
- **Permission Management**: permission_handler
- **Local Storage**: shared_preferences
- **Clipboard**: super_clipboard
- **Device Information**: device_info_plus

### Network Architecture

```
┌─────────────┐                    ┌─────────────┐
│   Device A  │                    │   Device B  │
│             │                    │             │
│ HTTP Client │ ──────────────────> │ HTTP Server │
│             │   File Transfer    │             │
│             │      Request       │ (Port 9527) │
│ HTTP Server │ <────────────────── │ HTTP Client │
│ (Port 9527) │   File Transfer    │             │
└─────────────┘      Request       └─────────────┘
```

### File Transfer Flow

```
Sender                                Receiver
  │                                    │
  ├─ 1. Health Check ─────────────────>│
  │<──────────────────────── Return Status │
  │                                    │
  ├─ 2. Batch Confirm Request ────────>│
  │   (Contains file list)             │
  │                                    ├─ Show confirmation dialog
  │                                    │
  │<──────────────────── 3. Return Confirmation │
  │   (Contains transferIds)           │
  │                                    │
  ├─ 4. Concurrent File Transfer ─────>│
  │   (Based on concurrency limit)     ├─ Receive and save files
  │                                    │
  ├─ 5. Save send history              ├─ 6. Save receive history
  │                                    │
```

---

## 🛠️ Development Guide

### Code Standards

- Follow Dart official style guide
- Use `flutter_lints` for code checking
- All public APIs must have documentation comments
- Use meaningful variable and function names

### Testing

The project includes unit tests and integration tests:

```bash
# Run all tests
flutter test

# Run tests and generate coverage report
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Logging System

The project uses a custom logging utility `LogUtil`:

```dart
import 'package:icy_easy_send/utils/log_util.dart';

// Info log
LogUtil.iTag
('TAG
'
,
'This is an info log
'
);

// Warning log
LogUtil.wTag('TAG', 'This is a warning log');

// Error log
LogUtil.eTag('TAG', '
This is an error log
'
,
error
,
stackTrace
);
```

### Adding New Features

1. Create new service classes in `lib/services/`
2. Define data models in `lib/models/`
3. Create UI pages in `lib/pages/`
4. Add utility functions in `lib/utils/`
5. Write unit tests
6. Update documentation

### Adding a New Language

The application supports internationalization (i18n). To add a new language, follow these steps:

#### 1. Create Translation Files

Create a new translation file in `lib/l10n/`:

```dart
// lib/l10n/app_localizations_<language_code>.dart
// Example: app_localizations_ja.dart for Japanese

import 'app_localizations.dart';

class AppLocalizationsJa extends AppLocalizations {
  @override
  String get appName => 'アプリ名';

  @override
  String get home => 'ホーム';

// ... implement all abstract methods from AppLocalizations
}
```

#### 2. Update Provider Classes

Update the following provider classes to support the new language:

**a. Error Message Provider** (`lib/utils/error_message_provider.dart`):

```dart
String get networkConnectionFailed =>
    getMessage({
      'zh': '无法连接到目标设备',
      'en': 'Unable to connect to target device',
      'ja': 'ターゲットデバイスに接続できません', // Add new language
    });
```

**b. Transfer Status Provider** (`lib/utils/transfer_status_provider.dart`):

```dart
String get checkingTargetDevice =>
    getMessage({
      'zh': '正在检查目标设备...',
      'en': 'Checking target device...',
      'ja': 'ターゲットデバイスを確認中...', // Add new language
    });
```

**c. Network Diagnostics Provider** (`lib/utils/network_diagnostics_provider.dart`):

```dart
String get networkDiagnosticsReport =>
    getMessage({
      'zh': '网络诊断报告',
      'en': 'Network Diagnostics Report',
      'ja': 'ネットワーク診断レポート', // Add new language
    });
```

#### 3. Register the New Language

Update `lib/l10n/app_localizations.dart` to register the new locale:

```dart
@override
Future<AppLocalizations> load(Locale locale) async {
  if (locale.languageCode == 'zh') {
    if (locale.countryCode == 'HK') {
      return AppLocalizationsZhHk();
    }
    return AppLocalizationsZh();
  }
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  // add a new language
    case 'ja':
      return AppLocalizationsJa();
  }
}
```

#### 4. Update Language Service

Update `lib/services/language_service.dart` to add the new language configuration:

```dart

static const Map<String, LanguageConfig> _supportedLanguages = {
  'system': LanguageConfig(
    code: 'system',
    displayName: 'System Default / 跟随系统',
    locale: Locale('en', 'US'),
  ),
  'zh': LanguageConfig(
    code: 'zh',
    displayName: '简体中文',
    locale: Locale('zh', 'CN'),
  ),
  'en': LanguageConfig(
    code: 'en',
    displayName: 'English',
    locale: Locale('en', 'US'),
  ),
  'ja': LanguageConfig( // Add new language - only need to add here!
    code: 'ja',
    displayName: '日本語',
    locale: Locale('ja', 'JP'),
  ),
};
```

## 📦 Dependencies

### Main Dependencies

| Package                | Version | Purpose               |
|------------------------|---------|-----------------------|
| shelf                  | ^1.4.2  | HTTP server framework |
| shelf_router           | ^1.1.4  | Routing management    |
| http                   | ^1.2.2  | HTTP client           |
| file_picker            | ^10.3.8 | File selection        |
| path_provider          | ^2.1.5  | Path access           |
| permission_handler     | ^12.0.1 | Permission management |
| shared_preferences     | ^2.3.3  | Local storage         |
| device_info_plus       | ^11.5.0 | Device information    |
| connectivity_plus      | ^7.0.0  | Network monitoring    |
| super_clipboard        | ^0.9.1  | Clipboard operations  |
| desktop_drop           | ^0.7.0  | Drag and drop support |
| flutter_sharing_intent | ^2.0.4  | Sharing intent        |

For complete dependency list, see [pubspec.yaml](pubspec.yaml) (versions listed here may be outdated, please refer to
the configuration file)

---

## 🔧 Configuration

### Network Configuration

- **Default Port**: 9527
- **Port Range**: 9527-9537 (automatically selects available port)
- **Request Timeout**: 30 seconds
- **Health Check Timeout**: 5 seconds
- **File Transfer Timeout**: 60 seconds + file size related

### File Limits

- **Maximum File Size**: 20GB
- **Maximum Clipboard Size**: 2MB (configurable 1-10MB)
- **Concurrent Transfers**: 5 (configurable 1-10)

### History Records

- **Default Retention Count**: 100 records
- **Configurable Range**: 10-1000 records

---

## 🐛 Troubleshooting

### Cannot Connect to Target Device

1. Ensure both devices are on the same LAN
2. Check firewall settings to ensure port 9527 is not blocked
3. Confirm the target device's application is running
4. Use network diagnostic tools to check connection

### File Transfer Failed

1. Check if receiving device has sufficient storage space
2. Confirm file size doesn't exceed 20GB limit
3. Check if network connection is stable
4. View error information in history records

### Permission Issues

1. Check app permissions in settings
2. Manually grant storage, photo library, and other permissions
3. If permissions are permanently denied, manually enable them in system settings

---

## 📄 License

This project is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**冰冷的希望 (Icy Hope)**

---

## 🙏 Acknowledgments

Thanks to all open source project contributors, especially:

- Flutter Team
- Dart Team
- All dependency package maintainers

---

## 📮 Contact

For questions or suggestions, feel free to contact via:

- Submit an Issue
- Create a Pull Request

---

<div align="center">

**If this project helps you, please give it a ⭐️**

Made with ❤️ by 冰冷的希望

</div>
