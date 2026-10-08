# Debug：本机环境到真机 / 模拟器 Run

默认路径。目录不同时，先在当前 PowerShell 设置再执行后面的命令：

```powershell
$env:FLUTTER_OH_ROOT = "F:\flutter_flutter_ohos_341"
$env:HOS_SDK_HOME    = "F:\harmony-sdk\default"   # 或 DevEco 的 sdk\default
$env:OHOS_DEPS_ROOT  = "F:\ohos-deps-341"
$env:DEVECO_ROOT     = "C:\Program Files\Huawei\DevEco Studio"
```

需要 **HarmonyOS SDK API 24（6.1.1）**。脚本在 `F:\harmony-sdk\default\sdk-pkg.json` 不存在时，会用 DevEco 自带的 `sdk\default`。

## 1. 安装 DevEco 与 SDK

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（本机用过 6.1.x）
2. **Tools → SDK Manager**（或 **File → Settings → HarmonyOS SDK**）安装 **API 24 / 6.1.1**
3. 确认存在：`C:\Program Files\Huawei\DevEco Studio\sdk\default\sdk-pkg.json`  
   若 SDK 装在别处，把该目录设为 `$env:HOS_SDK_HOME`

## 2. 安装 Flutter-OH（不要覆盖官方 Flutter，不要 `flutter upgrade`）

```powershell
git clone --branch oh-3.41.9-release --single-branch --depth 1 `
  https://gitcode.com/CPF-Flutter/flutter_flutter.git `
  F:\flutter_flutter_ohos_341

F:\flutter_flutter_ohos_341\bin\flutter.bat config --ohos-sdk="F:\harmony-sdk\default"
```

SDK 在 DevEco 内置目录时，把 `--ohos-sdk` 换成：

`C:\Program Files\Huawei\DevEco Studio\sdk\default`

## 3. 拉代码并准备工程

```powershell
git clone <仓库 URL> icy-easy-send
cd icy-easy-send
git checkout feat/support_harmony_os
git config --global core.longpaths true

.\installers\HarmonyOS\fix-flutter-version.ps1
.\installers\HarmonyOS\flutter-oh.cmd doctor -v
.\installers\HarmonyOS\prefetch-deps.ps1
.\installers\HarmonyOS\pub-get.ps1
.\installers\HarmonyOS\apply-ohos-native.ps1
```

`doctor` 需看到 HarmonyOS toolchain 与 Dart 3.11.x。不要执行 `flutter create --platforms=ohos`。

## 4. DevEco 打开并自动签名

1. DevEco **Open** → `<repo>\ohos`（不是仓库根）
2. USB 连真机并开调试，或启动模拟器
3. **File → Sync and Refresh Project**
4. **File → Project Structure → Project → Signing Configs**
5. 登录华为账号 → 勾选 **Automatically generate signature** → **Apply**（保留名为 `default` 的自动签名）
6. 切到调试签名后，再 **Sync** → **Run**：

```powershell
.\installers\HarmonyOS\switch-signing-config.ps1 -Name default
```

Deploy 日志里应是 `entry-default-signed.hap`。打商店包用 `-Name release`，见 [`release-signing.md`](./release-signing.md)。不要用 `ensure-signing-config.ps1` 切换，它发现已经绑定就退出，不会改当前签名。

命令行等价：

```powershell
.\installers\HarmonyOS\flutter-oh.cmd devices
.\installers\HarmonyOS\flutter-oh.cmd run
```

## 故障

| 报错 | 处理 |
|------|------|
| `9568320` / `no signature file` / 装的是 `*-unsigned.hap` | `switch-signing-config.ps1 -Name default`，Sync 后再 Run |
| `9568263` version downgrade | `apply-ohos-native.ps1` 后卸载再装：`hdc uninstall com.icyhope.icy_easy_send` |
| Sync 找不到插件 `build-profile.json5` | `repair-ohos-deps.ps1` 再 `pub-get.ps1` |
| `file_picker` / `file_picker_ohos`（`00303053`） | 再跑 `pub-get.ps1` |
| 缺 `ohos/local.properties` | 再跑 `apply-ohos-native.ps1` |
| `00303242` | 删掉 Signing Configs 里该项，重新勾选自动签名并 Apply，再 `switch-signing-config.ps1 -Name default` |

发布包与上架见 [`release-signing.md`](./release-signing.md)。
