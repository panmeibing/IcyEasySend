# Icy Easy Send

<div align="center">

![Version](https://img.shields.io/badge/version-1.5.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-BSD--3--Clause-green.svg)

一个高效、跨平台的文件传输应用——默认走局域网，也可自建中转实现跨网传输

[English](README.md) | [简体中文](README_CN.md)

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用说明](#使用说明) • [技术架构](#技术架构) • [开发指南](#开发指南)

</div>

---

## 📖 简介

Icy Easy Send 是一款基于 Flutter 的文件传输与剪切板同步工具。同一局域网内无需联网、无需注册即可使用；跨网段时，可连接自建的中转服务（`relayd`），在配对后进行端到端加密的文件传输与剪切板同步。

### 为什么选择 Icy Easy Send？

- 🚀 **高速传输**: 有局域网时直连，速度仅受限于网络带宽
- 🔒 **安全可靠**: 局域网流量不出本网；中转流量端到端加密，服务器只能看到密文
- 🌐 **跨网可选**: 自建中转并配对后，可在不同局域网间传文件、同步剪切板
- 📱 **跨平台支持**: 一套代码，支持 Android、iOS、Windows、macOS、Linux
- 🎯 **简单易用**: 扫描设备或输入 IP；中转场景用设备码配对即可
- 📦 **批量传输**: 支持一次性发送多个文件，自动管理传输队列
- 📋 **剪切板同步**: 跨设备同步文本、文件和图片（局域网或中转）

---

## ✨ 功能特性

### 核心功能

- **文件传输**
    - 支持单个或批量文件传输
    - 实时显示传输进度、速度和剩余时间
    - 自动处理文件名冲突
    - 支持大文件传输（最大 20GB）
    - 可配置并发传输数量（1-10 个文件同时传输）
    - 可选自建中转：端到端加密、断点续传、局域网优先选路

- **设备配对**
    - 通过短数字（SAS）确认信任关系（同网或经中转）
    - 中转场景用设备码配对；可对骚扰请求显式拉黑并管理黑名单

- **剪切板同步**
    - 跨设备同步文本内容
    - 支持文件 URI 同步
    - 支持图片格式（PNG、JPEG、BMP）
    - 可配置剪切板大小限制（1-10MB）
    - 支持局域网 HTTP，也支持经中转（小内容走信令，大内容走加密数据流）

- **用户体验**
    - 拖放文件支持（桌面平台）
    - 从其他应用分享文件到本应用
    - IP 历史与设备扫描（局域网 + 中转在线设备）
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
    - 在「目标 IP」输入接收方地址，或点击扫描并从列表选择局域网 / 中转在线设备
    - 点击「选择文件」选择要发送的文件（或直接拖放文件）
    - 点击「发送」
    - 接收方确认后开始传输（双通道可用时优先局域网）

3. **接收文件**
    - 保持应用运行
    - 当有人向你发送文件时，会弹出确认对话框
    - 查看文件列表并点击「接收」
    - 文件会自动保存到下载文件夹

4. **同步剪切板**
    - 选定对端（输入 IP，或主页上扫描选中的设备芯片）
    - 点击主页的「同步对方剪切板」
    - 对方确认后，其剪切板内容会同步到你的设备

5. **跨网中转（可选）**
    - 在自己的服务器上部署 `relayd`（见 [`relay/README.md`](relay/README.md)）
    - 在设置页填写中转地址与接入令牌（卡片位于「已配对设备」上方）
    - 双方在「通过中转配对」中输入对方设备码，并通过电话等渠道核对屏幕上的 6 位数字
    - 配对且中转在线后，无需同一局域网即可传文件或同步剪切板

6. **查看历史**
    - 切换到「历史」标签页
    - 查看所有传输记录
    - 可以筛选、打开文件或删除记录

### 高级设置

在「设置」页面可以配置：

- **设备名称**: 自定义设备名称，方便其他设备识别
- **中转服务器**: 地址与令牌；是否允许接收中转配对；在「已配对设备」旁管理配对黑名单
- **并发传输数**: 设置同时传输的文件数量（1-10）
- **历史记录数**: 设置保留的历史记录数量（10-1000）
- **剪切板大小**: 设置剪切板内容的最大大小（1-10MB）
- **IP 验证**: 开启/关闭 IP 地址格式验证

中转相关设计说明见 [`docs/relay-design.md`](docs/relay-design.md)。

---

## 🏗️ 技术架构

### 项目结构

```
lib/
├── main.dart                          # 应用入口
├── l10n/                              # 国际化（ARB 源文件 + 生成代码）
│   ├── app_en.arb                    # 模板语言（新增文案先改这里）
│   ├── app_*.arb                     # 其他语言
│   ├── app_localizations*.dart       # 由 `flutter gen-l10n` 生成（不要手改）
│   └── current_localizations.dart    # 服务层无 context 查找（`appText`）
├── models/                            # 数据模型
├── pages/                             # UI 页面
│   ├── home_page.dart                # 主页（编排）
│   ├── history_page.dart
│   ├── settings_page.dart            # 设置页（编排）
│   ├── main_container.dart
│   ├── home/                         # 主页控制器与分区组件
│   ├── settings/                     # 设置页控制器与卡片
│   ├── pairing/                      # 配对确认 UI
│   └── history/                      # 历史页相关组件
├── services/                          # 业务逻辑服务
│   ├── http_server_manager.dart
│   ├── file_transfer_service.dart
│   ├── clipboard_service.dart
│   ├── identity_service.dart         # 设备身份（Ed25519）
│   ├── pairing_service.dart
│   ├── language_service.dart         # 语言偏好
│   ├── relay/                        # 中转客户端（WSS、加密、配对、剪切板）
│   └── transfer/                     # 文件收发、批量、健康检查
├── transport/                         # 通道抽象（局域网 / 中转 / 选路）
└── utils/                             # 通用工具（日志、网络、对话框等）
```

自建中转服务端代码在仓库 `relay/` 目录，说明见 [`relay/README.md`](relay/README.md)；协议设计见 [`docs/relay-design.md`](docs/relay-design.md)。

### 核心技术栈

- **UI 框架**: Flutter 3.41.2+
- **国际化**: flutter_localizations + intl（`lib/l10n/*.arb`，`flutter gen-l10n`）
- **HTTP 服务器**: shelf + shelf_router
- **网络通信**: http + dio + connectivity_plus；中转信令为 WebSocket（`dart:io`）
- **文件操作**: file_picker + path_provider
- **权限管理**: permission_handler
- **本地存储**: shared_preferences
- **剪切板**: super_clipboard
- **密码学**: cryptography（中转 E2E）
- **设备信息**: device_info_plus
- **中转服务端**: Go（`relayd`）

### 网络架构

```
局域网（默认）:
┌─────────────┐                    ┌─────────────┐
│   设备 A    │                    │   设备 B    │
│  HTTP 客户端 │ ──────────────────> │  HTTP 服务器 │
│  HTTP 服务器 │ <────────────────── │  HTTP 客户端 │
└─────────────┘     (端口 9527)     └─────────────┘

跨网（可选，自建中转）:
┌─────────────┐     WSS + HTTPS      ┌──────────┐     WSS + HTTPS      ┌─────────────┐
│   设备 A    │ <──────────────────> │  relayd  │ <──────────────────> │   设备 B    │
└─────────────┘   信令 / 加密数据流   └──────────┘   信令 / 加密数据流   └─────────────┘
```

### 文件传输流程

局域网路径大致如下（中转路径为信令握手 + 加密分块流，详见设计文档）：

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

```bash
# 静态分析（CI 也会跑）
flutter analyze

# 单元 / Widget 测试
flutter test

# 覆盖率（可选）
flutter test --coverage
```

CI（`.github/workflows/ci.yml`）会对 Flutter/Dart 变更执行 `flutter analyze` 与 `flutter test`。中转 Go 侧检查见 `relay-ci.yml`。

### 日志系统

项目使用自定义的日志工具 `LogUtil`：

```
import 'package:icy_easy_send/utils/log_util.dart';

// 信息日志
LogUtil.iTag('TAG','这是一条信息日志');

// 警告日志
LogUtil.wTag('TAG', '这是一条警告日志');

// 错误日志
LogUtil.eTag('TAG', '这是一条错误日志', error, stackTrace);
```

### 添加新功能

1. 在 `lib/services/` 中创建新的服务类
2. 在 `lib/models/` 中定义数据模型
3. 在 `lib/pages/` 中创建 UI 页面
4. 在 `lib/utils/` 中添加工具函数
5. 编写单元测试
6. 更新文档

### 国际化（i18n）

所有面向用户的文案只维护在一处：`lib/l10n/` 下的 ARB 文件。
通过 `pubspec.yaml` 的 `generate: true` 与根目录 `l10n.yaml`，构建时会跑
`flutter gen-l10n`，生成 `app_localizations*.dart`。生成文件会提交进仓库，
干净检出即可编译——**请改 `.arb`，不要手改生成出来的 Dart**。

| 场景 | 取文案方式 |
|------|------------|
| Widget | `AppLocalizations.of(context)` —— 必须用 context，语言切换时 UI 才会重建 |
| 服务层 / HTTP / 通知（没有 `BuildContext`） | `lib/l10n/current_localizations.dart` 里的 `appText` |

`ErrorMessages` 等薄门面仍可调用，内部已委托给 `appText`，**不再自带多语言对照表**。

当前支持：`zh`、`zh_HK`、`en`、`ko`、`ja`、`fr`、`de`、`es`、`pt`、`ru`、`it`、`nl`（设置里还可「跟随系统」）。

#### 新增一条文案

1. 在 `lib/l10n/app_en.arb` 增加 key（需要占位符时一并写 `@key`）。
2. 在其余 `lib/l10n/app_*.arb` 中补上同名 key。
3. 运行 `flutter gen-l10n`（或 `flutter pub get` / 正常构建）。
4. UI 用 `AppLocalizations.of(context).yourKey`，服务层用 `appText.yourKey`。

未翻译的 key 会写到 `lib/l10n/untranslated.json`（已 gitignore）。

#### 添加新语言

1. **新建** `lib/l10n/app_<code>.arb`（可复制 `app_en.arb`，改 `"@@locale"` 并翻译）。
2. 在 `lib/services/language_service.dart` 的 `_supportedLanguages` **注册**该语言。
3. 运行 `flutter gen-l10n`，在设置页确认新语言出现。

不必再手写 `app_localizations_<code>.dart`，也不必维护第二套 message provider。

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

1. 检查接收设备的存储空间是否充足（磁盘满时会弹出专门提示）
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
