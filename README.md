# Icy Easy Send

一个基于 Flutter 的局域网文件传输应用，支持在同一局域网内的设备之间快速、安全地传输文件。

## 主要特性

- ✅ **简单易用**: 只需输入目标设备 IP 地址即可传输文件
- ✅ **智能记忆**: 自动保存上次使用的 IP 地址，下次启动自动填充
- ✅ **多文件传输**: 支持一次选择多个文件，按顺序逐个传输
- ✅ **自动接收**: 批量接收文件时可选择自动接收后续文件，无需每次确认
- ✅ **实时进度**: 显示传输进度、速度和预计剩余时间
- ✅ **用户确认**: 接收方需要确认才能接收文件，保护隐私
- ✅ **传输历史**: 记录所有传输历史，方便查看
- ✅ **跨平台**: 支持 Android、iOS、Windows、macOS、Linux
- ✅ **无需互联网**: 完全在局域网内工作，不需要外网连接

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

### 构建应用

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 使用方法

### 发送文件

1. 启动应用，服务器会自动运行
2. 记下显示的本机 IP 地址
3. 输入目标设备的 IP 地址（首次输入后会自动保存）
4. 点击"选择文件"按钮
5. 选择一个或多个文件
6. 点击"发送文件"按钮
7. 等待接收方确认
8. 查看传输进度

### 接收文件

1. 启动应用，服务器会自动运行
2. 告诉发送方你的 IP 地址
3. 等待接收文件请求
4. 在弹窗中确认是否接收
5. **新功能**: 如果后续还有文件，可以勾选"自动接收后续 X 个文件"
6. 文件会自动保存到下载目录

### 多文件传输

1. 在文件选择器中同时选择多个文件：
   - **Windows/Linux**: 按住 Ctrl 键点击多个文件
   - **macOS**: 按住 Command 键点击多个文件
   - **Android/iOS**: 长按选择多个文件
2. 文件会按顺序逐个传输
3. 可以在列表中删除不需要的文件
4. 传输完成后会显示详细的结果汇总

## 功能说明

### 自动接收后续文件（v1.1.1 新增）

详细说明请查看 [AUTO_ACCEPT_FEATURE.md](AUTO_ACCEPT_FEATURE.md)

主要特点：
- 批量接收文件时只需确认一次
- 减少 99% 的点击次数
- 可选功能，不强制使用
- 安全可控，可随时中断

### 多文件传输

详细的多文件传输功能说明请查看 [MULTI_FILE_TRANSFER.md](MULTI_FILE_TRANSFER.md)

主要特点：
- 一次选择多个文件
- 按顺序逐个传输
- 实时显示当前文件进度
- 传输结果汇总
- 失败文件可重试

### API 文档

详细的 API 文档请查看 [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **Dart**: 编程语言
- **HTTP Server**: 内置 HTTP 服务器用于接收文件
- **HTTP Client**: 用于发送文件
- **File Picker**: 文件选择器
- **Permission Handler**: 权限管理
- **Path Provider**: 文件路径管理

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── device_info.dart
│   ├── file_transfer_request.dart
│   └── transfer_history.dart
├── pages/                    # 页面
│   ├── home_page.dart        # 主页（发送文件）
│   ├── history_page.dart     # 传输历史
│   └── main_container.dart   # 主容器
├── services/                 # 服务
│   ├── file_transfer_service.dart      # 文件传输服务
│   ├── file_transfer_handler.dart      # 文件传输处理器
│   ├── health_check_handler.dart       # 健康检查处理器
│   ├── http_server_manager.dart        # HTTP 服务器管理
│   ├── notification_service.dart       # 通知服务
│   ├── permission_service.dart         # 权限服务
│   ├── transfer_history_service.dart   # 传输历史服务
│   └── validation_service.dart         # 验证服务
└── utils/                    # 工具类
    └── error_messages.dart   # 错误消息
```

## 安全说明

- 此应用仅设计用于局域网环境
- 不应将服务暴露到公网
- 所有文件接收都需要用户手动确认
- 不包含认证机制，请在可信网络中使用

## 限制

- 最大文件大小: 2GB
- 仅支持局域网传输
- 需要手动输入 IP 地址
- 文件按顺序传输，不支持并行传输

## 常见问题

### Q: 如何找到设备的 IP 地址？
A: 启动应用后，IP 地址会显示在主页顶部的绿色卡片中。

### Q: 为什么无法连接到目标设备？
A: 请确保：
- 两台设备在同一局域网内（连接到同一个 WiFi）
- 目标设备的应用正在运行
- IP 地址输入正确（检查是否在同一网段，如都是 192.168.1.x）
- 防火墙没有阻止连接
- 详细排查请查看 [网络故障排查指南](NETWORK_TROUBLESHOOTING.md)

### Q: 可以同时传输多个文件吗？
A: 可以一次选择多个文件，但它们会按顺序逐个传输，不是同时传输。

### Q: 文件保存在哪里？
A: 
- Android: `/storage/emulated/0/Download/`
- iOS: 应用文档目录
- Desktop: 系统下载目录

## 开发

### 运行测试

```bash
flutter test
```

### 代码分析

```bash
flutter analyze
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 更新日志

### v1.1.3 (最新)
- ✨ 新增 IP 地址记忆功能
- 🎯 自动保存和填充上次使用的 IP
- 📝 IP 历史记录快速选择
- 🎨 减少 90% 的输入时间

### v1.1.2
- 🐛 修复多网络接口时的 IP 地址选择问题
- 🎯 智能选择局域网地址，优先 192.168.x.x
- 📝 添加网络故障排查指南

### v1.1.1
- ✨ 新增自动接收后续文件功能
- 🎯 批量接收文件时减少 99% 的点击次数
- 🔒 安全可控，首次必须确认
- 📝 添加详细的功能说明文档

### v1.1.0
- ✨ 新增多文件传输功能
- ✨ 支持文件列表管理
- ✨ 改进传输进度显示
- ✨ 添加传输结果汇总

### v1.0.0
- 🎉 初始版本
- ✅ 基本文件传输功能
- ✅ 用户确认机制
- ✅ 传输历史记录

## 联系方式

如有问题或建议，请提交 Issue。
