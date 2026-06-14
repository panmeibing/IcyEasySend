# GitHub Actions 发版配置

本项目的 Release 工作流位于 [`.github/workflows/release.yml`](../workflows/release.yml)。

## 触发方式

### 1. 打 tag 自动发版（推荐）

```bash
git tag v1.3.0
git push origin v1.3.0
```

工作流会自动：

1. 构建全平台产物（不含 iOS）
2. 创建一个 **Draft（草稿）Release**
3. 上传所有安装包到该 Release

你只需在 GitHub → Releases 页面打开草稿，**手动填写 Release Notes**，然后点击 **Publish release**。

### 2. 手动触发

GitHub → Actions → Release → Run workflow

- **version**：版本号，不带 `v` 前缀，例如 `1.3.0`
- **create_draft_release**：是否创建草稿 Release 并上传附件
  - 勾选：行为类似 tag 发版
  - 不勾选：仅构建并保留 Actions Artifacts（90 天）

## 产物列表

| 平台 | 文件名示例 |
|------|------------|
| Linux amd64 | `IcyEasySend-linux-amd64-v1.3.0.deb` / `.tar.gz` |
| Linux arm64 | `IcyEasySend-linux-arm64-v1.3.0.deb` / `.tar.gz` |
| Windows x64 | `IcyEasySend_setup_1.3.0.exe` |
| macOS | `IcyEasySend-macOS-v1.3.0.dmg`（未签名） |
| Android | `IcyEasySend-android-v1.3.0.apk` / `.aab` |

## 必须配置的 GitHub Secrets

仓库 Settings → Secrets and variables → Actions → New repository secret

| Secret | 说明 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | `icy_easy_send_key.jks` 的 Base64 编码 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 别名，例如 `icyeasysend` |
| `ANDROID_KEY_PASSWORD` | key 密码 |

### 生成 Base64 keystore（PowerShell）

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/icy_easy_send_key.jks")) | Set-Clipboard
```

将剪贴板内容粘贴到 `ANDROID_KEYSTORE_BASE64`。

> **注意**：请勿将 `*.jks` 和 `android/key.properties` 提交到 git。

## CI 环境说明

- 使用国内 Flutter 镜像：`pub.flutter-io.cn` / `storage.flutter-io.cn`
- Flutter git 源：`gitee.com/mirrors/Flutter.git`
- Windows 安装包使用 Inno Setup，中文语言包来自 `installers/Windows/ChineseSimplified.isl`
- Linux 构建依赖 Rust（`super_native_extensions`）
- macOS 产物未签名，用户首次打开可能需要右键 → 打开

## 发版前检查清单

- [ ] `pubspec.yaml` 版本号与 tag 一致（tag `v1.3.0` ↔ version `1.3.0+…`）
- [ ] Android Secrets 已配置
- [ ] `installers/Windows/ChineseSimplified.isl` 已提交
- [ ] 在 `main` 分支（或合并后的发版分支）上打 tag

## 常见问题

### Linux arm64 job 失败（其他平台成功）

常见原因与处理：

1. **`subosito/flutter-action` 不支持 Linux arm64 SDK 解析**（报错 `Unable to determine Flutter version ... architecture: arm64`）。arm64 job 已改为 `git clone` 安装 Flutter，不再使用 flutter-action。
2. **Flutter Actions 缓存污染**：amd64 job 使用独立 cache key；arm64 不使用 flutter-action。
3. **依赖包名称**：Ubuntu 24.04 请使用 `libstdc++-13-dev`（不是 `-12-dev`）。
4. **脚本换行符**：Windows 提交的 `.sh` 若含 CRLF 会在 Linux 上失败；CI 已自动执行 `sed` 修复。
5. **GitHub arm runner 迁移**：2026-06-08 ~ 06-15 期间 `ubuntu-24.04-arm` 可能不稳定，可稍后重试。

重新触发 arm64 构建：删除失败的 tag/release 后重新 push tag，或在 Actions 里手动 Run workflow。
