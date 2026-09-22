# HarmonyOS 分支

分支：`feat/support_harmony_os`。与 `main` 的差别如下。

| | `main` | 本分支 |
|--|--------|--------|
| Flutter | 官方 SDK，命令用 `flutter` | Flutter-OH `oh-3.41.9-release`，命令只用 `installers\HarmonyOS\flutter-oh.cmd` |
| 工程 | `android/` `ios/` 桌面 | 另有入库的 `ohos/` |
| 依赖 | `pubspec.yaml` | `pubspec.yaml` 相同；OH 插件由 `pub-get.ps1` 写入根目录 `pubspec_overrides.yaml`（gitignore） |

切回 `main` 前：删除根目录 `pubspec_overrides.yaml`，再用官方 `flutter pub get`。

不要提交：`ohos/build-profile.json5`、`ohos/local.properties`、`oh_modules/`、`**/build/`、`*.hap`、`*.app`、`.p12` / `.cer` / `.p7b`、根目录 `pubspec_overrides.yaml`。

## 文档

| 文档 | 内容 |
|------|------|
| [`run-ohos.md`](./run-ohos.md) | 本机环境 + 自动签名调试运行 |
| [`release-signing.md`](./release-signing.md) | 发布签名、构建 `.app`、上传应用市场 |
