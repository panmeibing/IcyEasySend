# Release：发布签名、构建、上传应用市场

前提：已按 [`run-ohos.md`](./run-ohos.md) 能用自动签名 Run。  
**保留** Signing Configs 里的 `default`（自动签名）。另加 `release`。不要取消 Automatically generate。

发布证书的包**不能** `hdc install`（`9568448` / `9568322`）。真机验证走 AGC 邀请测试；日常调试用 `default`。

材料目录（勿提交 Git）：

```text
F:\harmony-signing\release\
  IcyEasySend-release.p12
  IcyEasySend-release.cer
  IcyEasySend-release.csr
  IcyEasySend-releaseRelease.p7b
```

包名：`com.icyhope.icy_easy_send`（`ohos/AppScope/app.json5`）。

## 1. 生成密钥并申请证书 / Profile

1. DevEco 打开 `<repo>\ohos`
2. **Build → Generate Key and CSR**

| 项 | 值 |
|----|----|
| Key Store | `F:\harmony-signing\release\IcyEasySend-release.p12` |
| Key Alias | `IcyEasySendRelease` |
| CSR | `F:\harmony-signing\release\IcyEasySend-release.csr` |

3. [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) → 该 HarmonyOS 应用（没有则新建，包名与上面一致）
4. 用 `.csr` 申请**发布证书** → 下载 `.cer` 到上述目录
5. 新建 **Release Profile**，选该发布证书，勾选：
   - `ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY`
   - `ohos.permission.READ_PASTEBOARD`  
   列表没有时，先在应用的 ACL / 受限权限入口申请，通过后再建 Profile  
   说明：[受限权限](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/declare-permissions-in-acl)、[发布 Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-harmonyos-profile)
6. 下载 `.p7b` 为 `IcyEasySend-releaseRelease.p7b`

```powershell
.\installers\HarmonyOS\verify-release-materials.ps1
```

## 2. DevEco 增加 `release` 签名

**File → Project Structure → Project → Signing Configs** → **+**，名称 `release`，不要勾自动签名。三项都选 `F:\harmony-signing\release\`：

| 字段 | 文件 |
|------|------|
| Store File | `IcyEasySend-release.p12` |
| Key Alias | `IcyEasySendRelease` |
| Certificate | `IcyEasySend-release.cer` |
| Profile | `IcyEasySend-releaseRelease.p7b` |

填 Store / Key 密码 → **Apply**。只改密码时 Apply 发灰：重新浏览一遍三个文件后再填密码。

不要手改 `ohos/build-profile.json5` 里的密码密文。不要把 cer 指到 `%USERPROFILE%\.ohos\config\`。

## 3. 发版号与图标（每次上架）

`ohos/AppScope/app.json5`：`versionCode` 必须大于上一版，`versionName` 与商店一致。同步：

- `pubspec.yaml` 的 `version`
- `lib/utils/constants.dart` 的 `AppConstants.version`

换图标：

```powershell
.\installers\HarmonyOS\generate-ohos-layered-icons.ps1
```

商店图标必须是分层 1024×1024（`app_layered_image` / `layered_image` 的 foreground + background），不要用 `icon.jpg` 或 `start_icon`。

## 4. 构建 `.app`

```powershell
.\installers\HarmonyOS\switch-signing-config.ps1 -Name release
```

DevEco：**File → Sync and Refresh Project** → **Build → Build Hap(s)/APP(s) → Build APP(s)**

产物：

```text
ohos\build\outputs\default\ohos-default-signed.app
```

只用 **signed**。不要上传 `ohos-default-unsigned.app` 或 HAP。

打完切回调试：

```powershell
.\installers\HarmonyOS\switch-signing-config.ps1 -Name default
```

再 Sync。之后日常 Run 仍走自动签名。

## 5. 上传

1. [AGC](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) → 该应用 → **版本信息 / 软件包管理**
2. 上传 `ohos-default-signed.app`
3. 填简介、截图、隐私政策、权限说明 → **提交审核**
4. 先给测试账号：同一页面走 **邀请测试 / 开放测试**，测试员用华为账号在应用市场或测试链接安装

## 故障

| 报错 | 处理 |
|------|------|
| `11014001` Key alias not found | Alias 改为 `IcyEasySendRelease`，重新填密码 Apply |
| `00303107` Invalid storeFile | 核对 `F:\harmony-signing\release\*.p12` 存在 |
| `00303242` | 删掉 `release` 配置，按第 2 节重建并重填密码 |
| `9568448` / `9568322`（`hdc install` Release 包） | 正常。不要本地装发布包；用 AGC 邀请测试，或切回 `default` 再 Run |
| 云测 ACL 不一致 / `9568289` | 按第 1 步重下勾了两条权限的 `.p7b`，在 `release` 里换 Profile，再 Build APP |
| `9568263` | 提高 `versionCode`，或先卸载旧包 |
