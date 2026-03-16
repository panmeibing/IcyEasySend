# Icy Easy Send

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-BSD--3--Clause-green.svg)

一个高效、跨平台的局域网文件传输应用

[English](README.md) | [简体中文](README_CN.md)

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用说明](#使用说明) • [技术架构](#技术架构) • [开发指南](#开发指南)

</div>

---

## 📖 简介

Icy Easy Send 是一款基于 Flutter 开发的局域网文件传输工具，支持在同一局域网内的多个设备之间快速、安全地传输文件和同步剪切板内容。无需互联网连接，无需注册账号，即开即用。

### 为什么选择 Icy Easy Send？

- 🚀 **高速传输**: 局域网直连，传输速度仅受限于网络带宽
- 🔒 **安全可靠**: 数据不经过第三方服务器，完全在本地网络传输
- 📱 **跨平台支持**: 一套代码，支持 Android、iOS、Windows、macOS、Linux
- 🎯 **简单易用**: 无需复杂配置，输入 IP 地址即可开始传输
- 📦 **批量传输**: 支持一次性发送多个文件，自动管理传输队列
- 📋 **剪切板同步**: 跨设备同步文本、文件和图片

---

## ✨ 功能特性

### 核心功能

- **文件传输**
    - 支持单个或批量文件传输
    - 实时显示传输进度、速度和剩余时间
    - 自动处理文件名冲突
    - 支持大文件传输（最大 20GB）
    - 可配置并发传输数量（1-10 个文件同时传输）

- **剪切板同步**
    - 跨设备同步文本内容
    - 支持文件 URI 同步
    - 支持图片格式（PNG、JPEG、BMP）
    - 可配置剪切板大小限制（1-10MB）

- **用户体验**
    - 拖放文件支持（桌面平台）
    - 从其他应用分享文件到本应用
    - IP 地址历史记录
    - 实时 IP 地址验证
    - 网络状态监听和自动重连

- **历史记录**
    - 完整的传输历史记录
    - 按类型筛选（全部/已发送/已接收）
    - 传输统计信息
    - 快速打开文件或文件夹
    - 可配置历史记录保留数量

- **网络诊断**
    - 内置网络诊断工具
    - 检测网络连接状态
    - 端口可用性测试
    - 目标设备可达性检查

---

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.41.2 或更高版本
- Dart SDK: 3.11.0 或更高版本
- 对应平台的开发环境：
    - Android: Android Studio / Android SDK
    - iOS: Xcode (仅 macOS)
    - Windows: Visual Studio 2022
    - macOS: Xcode
    - Linux: 相关开发工具链

### 安装步骤

1. **克隆项目**

```bash
git clone <repository-url>
cd icy_easy_send
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行应用**

```bash
# Android
flutter run -d android

# iOS (需要 macOS)
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (需要 macOS)
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 📱 使用说明

### 基本使用流程

1. **启动应用**
    - 应用启动后会自动启动 HTTP 服务器
    - 在主页顶部可以看到本机的 IP 地址和端口号

2. **发送文件**
    - 在"目标 IP"输入框中输入接收方的 IP 地址
    - 点击"选择文件"按钮选择要发送的文件（或直接拖放文件）
    - 点击"发送"按钮
    - 接收方确认后开始传输

3. **接收文件**
    - 保持应用运行
    - 当有人向你发送文件时，会弹出确认对话框
    - 查看文件列表并点击"接收"
    - 文件会自动保存到下载文件夹

4. **同步剪切板**
    - 输入目标设备的 IP 地址
    - 点击主页的"同步对方剪切板"按钮
    - 对方确认后，其剪切板内容会同步到你的设备

5. **查看历史**
    - 切换到"历史"标签页
    - 查看所有传输记录
    - 可以筛选、打开文件或删除记录

### 高级设置

在"设置"页面可以配置：

- **设备名称**: 自定义设备名称，方便其他设备识别
- **并发传输数**: 设置同时传输的文件数量（1-10）
- **历史记录数**: 设置保留的历史记录数量（10-1000）
- **剪切板大小**: 设置剪切板内容的最大大小（1-10MB）
- **IP 验证**: 开启/关闭 IP 地址格式验证

---

## 🏗️ 技术架构

### 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/                            # 数据模型
│   ├── device_info.dart              # 设备信息
│   ├── file_transfer_request.dart    # 文件传输请求
│   ├── transfer_data.dart            # 传输数据
│   ├── transfer_history.dart         # 传输历史
│   └── clipboard_data_model.dart     # 剪切板数据
├── pages/                             # UI 页面
│   ├── home_page.dart                # 主页
│   ├── history_page.dart             # 历史页面
│   ├── settings_page.dart            # 设置页面
│   ├── main_container.dart           # 主容器
│   ├── controllers/                  # 页面控制器
│   └── widgets/                      # UI 组件
├── services/                          # 业务逻辑服务
│   ├── http_server_manager.dart      # HTTP 服务器管理
│   ├── file_transfer_service.dart    # 文件传输服务
│   ├── clipboard_service.dart        # 剪切板服务
│   ├── permission_service.dart       # 权限管理
│   ├── preferences_service.dart      # 本地存储
│   ├── transfer_history_service.dart # 历史记录管理
│   └── transfer/                     # 传输子模块
│       ├── file_sender.dart          # 文件发送
│       ├── file_receiver.dart        # 文件接收
│       ├── batch_transfer_manager.dart # 批量传输管理
│       └── health_checker.dart       # 健康检查
└── utils/                             # 工具函数
    ├── constants.dart                # 常量定义
    ├── network_util.dart             # 网络工具
    ├── format_util.dart              # 格式化工具
    └── log_util.dart                 # 日志工具
```

### 核心技术栈

- **UI 框架**: Flutter 3.41.2+
- **HTTP 服务器**: shelf + shelf_router
- **网络通信**: http + connectivity_plus
- **文件操作**: file_picker + path_provider
- **权限管理**: permission_handler
- **本地存储**: shared_preferences
- **剪切板**: super_clipboard
- **设备信息**: device_info_plus

### 网络架构

```
┌─────────────┐                    ┌─────────────┐
│   设备 A    │                    │   设备 B    │
│             │                    │             │
│  HTTP 客户端 │ ──────────────────> │  HTTP 服务器 │
│             │   文件传输请求      │             │
│             │                    │  (端口 9527) │
│  HTTP 服务器 │ <────────────────── │  HTTP 客户端 │
│  (端口 9527) │   文件传输请求      │             │
└─────────────┘                    └─────────────┘
```

### 文件传输流程

```
发送方                                接收方
  │                                    │
  ├─ 1. 健康检查 ──────────────────────>│
  │<─────────────────────────── 返回状态 │
  │                                    │
  ├─ 2. 批量确认请求 ──────────────────>│
  │   (包含文件列表)                    │
  │                                    ├─ 显示确认对话框
  │                                    │
  │<─────────────────────── 3. 返回确认 │
  │   (包含 transferIds)                │
  │                                    │
  ├─ 4. 并发传输文件 ──────────────────>│
  │   (根据并发数限制)                  ├─ 接收并保存文件
  │                                    │
  ├─ 5. 保存发送历史                   ├─ 6. 保存接收历史
  │                                    │
```

---

## 🛠️ 开发指南

### 代码规范

- 遵循 Dart 官方代码风格指南
- 使用 `flutter_lints` 进行代码检查
- 所有公共 API 必须有文档注释
- 使用有意义的变量和函数命名

### 测试

项目包含单元测试和集成测试：

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 日志系统

项目使用自定义的日志工具 `LogUtil`：

```dart
import 'package:icy_easy_send/utils/log_util.dart';

// 信息日志
LogUtil.iTag
('TAG
'
,
'
这是一条信息日
志
'
);

// 警告日志
LogUtil.wTag('TAG', '这是一条警告日志');

// 错误日志
LogUtil.eTag('TAG', '
这是一条错误日志
'
,
error
,
stackTrace
);
```

### 添加新功能

1. 在 `lib/services/` 中创建新的服务类
2. 在 `lib/models/` 中定义数据模型
3. 在 `lib/pages/` 中创建 UI 页面
4. 在 `lib/utils/` 中添加工具函数
5. 编写单元测试
6. 更新文档

### 添加新语言

应用支持国际化（i18n）。要添加新语言，请按照以下步骤操作：

#### 1. 创建翻译文件

在 `lib/l10n/` 目录下创建新的翻译文件：

```dart
// lib/l10n/app_localizations_<语言代码>.dart
// 示例：app_localizations_ja.dart 用于日语

import 'app_localizations.dart';

class AppLocalizationsJa extends AppLocalizations {
  @override
  String get appName => 'アプリ名';

  @override
  String get home => 'ホーム';

// ... 实现 AppLocalizations 中的所有抽象方法
}
```

#### 2. 更新 Provider 类

更新以下 provider 类以支持新语言：

**a. 错误消息提供者** (`lib/utils/error_message_provider.dart`)：

```dart
String get networkConnectionFailed =>
    getMessage({
      'zh': '无法连接到目标设备',
      'en': 'Unable to connect to target device',
      'ja': 'ターゲットデバイスに接続できません', // 添加新语言
    });
```

**b. 传输状态提供者** (`lib/utils/transfer_status_provider.dart`)：

```dart
String get checkingTargetDevice =>
    getMessage({
      'zh': '正在检查目标设备...',
      'en': 'Checking target device...',
      'ja': 'ターゲットデバイスを確認中...', // 添加新语言
    });
```

**c. 网络诊断提供者** (`lib/utils/network_diagnostics_provider.dart`)：

```dart
String get networkDiagnosticsReport =>
    getMessage({
      'zh': '网络诊断报告',
      'en': 'Network Diagnostics Report',
      'ja': 'ネットワーク診断レポート', // 添加新语言
    });
```

#### 3. 注册新语言

更新 `lib/l10n/app_localizations.dart` 以注册新的语言环境：

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
  // 添加新语言
    case 'ja':
      return AppLocalizationsJa();
  }
}
```

#### 4. 更新语言服务

更新 `lib/services/language_service.dart` 以添加新的语言配置：

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
  'ja': LanguageConfig( // 添加新语言 - 只需要在这里添加！
    code: 'ja',
    displayName: '日本語',
    locale: Locale('ja', 'JP'),
  ),
};
```

## 📦 依赖项

### 主要依赖

| 依赖包                    | 版本      | 用途         |
|------------------------|---------|------------|
| shelf                  | ^1.4.2  | HTTP 服务器框架 |
| shelf_router           | ^1.1.4  | 路由管理       |
| http                   | ^1.2.2  | HTTP 客户端   |
| file_picker            | ^10.3.8 | 文件选择       |
| path_provider          | ^2.1.5  | 路径获取       |
| permission_handler     | ^12.0.1 | 权限管理       |
| shared_preferences     | ^2.3.3  | 本地存储       |
| device_info_plus       | ^11.5.0 | 设备信息       |
| connectivity_plus      | ^7.0.0  | 网络监听       |
| super_clipboard        | ^0.9.1  | 剪切板操作      |
| desktop_drop           | ^0.7.0  | 拖放支持       |
| flutter_sharing_intent | ^2.0.4  | 分享意图       |

完整依赖列表请查看 [pubspec.yaml](pubspec.yaml)（此处列出的版本可能已经过时，请以配置文件为主）

---

## 🔧 配置说明

### 网络配置

- **默认端口**: 9527
- **端口范围**: 9527-9537（自动选择可用端口）
- **请求超时**: 30 秒
- **健康检查超时**: 5 秒
- **文件传输超时**: 60 秒 + 文件大小相关

### 文件限制

- **最大文件大小**: 20GB
- **最大剪切板大小**: 2MB（可配置 1-10MB）
- **并发传输数**: 5（可配置 1-10）

### 历史记录

- **默认保留数量**: 100 条
- **可配置范围**: 10-1000 条

---

## 🐛 常见问题

### 无法连接到目标设备

1. 确保两台设备在同一局域网内
2. 检查防火墙设置，确保端口 9527 未被阻止
3. 确认目标设备的应用正在运行
4. 使用网络诊断工具检查连接

### 文件传输失败

1. 检查接收设备的存储空间是否充足
2. 确认文件大小未超过 20GB 限制
3. 检查网络连接是否稳定
4. 查看历史记录中的错误信息

### 权限问题

1. 在设置中检查应用权限
2. 手动授予存储、照片库等权限
3. 如果权限被永久拒绝，需要在系统设置中手动开启

---

## 📄 许可证

本项目采用 BSD 3-Clause 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 👨‍💻 作者

**冰冷的希望**

---

## 🙏 致谢

感谢所有开源项目的贡献者，特别是：

- Flutter 团队
- Dart 团队
- 所有依赖包的维护者

---

## 📮 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 提交 Issue
- 发起 Pull Request

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️**

Made with ❤️ by 冰冷的希望

</div>
