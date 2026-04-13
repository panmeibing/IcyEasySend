# 编译 IcyEasySend（macOS）

## 1.构建发行版安装包

Build APP

```shell
flutter config --enable-macos-desktop
flutter build macos --release
```

> 构建完成后，生成的应用包位于：build/macos/Build/Products/Release/IcyEasySend.app

## 2.签名

### 2.1 创建本地证书

可以打开系统自带的“钥匙串访问”创建一个本地签名，证书类型选择“代码签名”，保存在“登录”钥匙串中，双击该证书，设置为“始终信任”

### 2.2 签名

**方式一：使用自动化签名脚本（推荐）**

创建签名脚本 `installers/macOS/sign_app.sh`：

使用方法：

```bash
# 1. 给脚本添加执行权限
chmod +x installers/macOS/sign_app.sh

# 2. 修改脚本中的 SIGNING_IDENTITY 为你的证书名称

# 3. 执行签名
cd installers/macOS
./sign_app.sh
```

**方式二：手动签名命令**

如果不想使用脚本，可以手动执行：

```shell
# 请将 "IcyHope" 替换为你的证书名称

codesign --deep --force --sign "IcyHope" \
--entitlements macos/Runner/Release.entitlements \
--options runtime \
--timestamp \
build/macos/Build/Products/Release/IcyEasySend.app

# 验证签名和权限
codesign --verify --deep --strict --verbose=2 \
build/macos/Build/Products/Release/IcyEasySend.app

# 查看应用的 entitlements（确保权限正确）
codesign -d --entitlements - \
build/macos/Build/Products/Release/IcyEasySend.app
```

> **重要说明**：
> - ✅ **自动化脚本会自动读取 entitlements 文件**，无需手动指定权限
> - ✅ 当项目添加新权限时，只需更新 `macos/Runner/Release.entitlements` 文件
> - ✅ 脚本会验证签名和权限配置，确保不会遗漏
> - ✅ `--timestamp` 参数添加时间戳，使签名长期有效
> - ⚠️ 如果是 Debug 版本，将脚本中的 `Release.entitlements` 改为 `DebugProfile.entitlements`

## 3.生成 dmg 文件

### 3.1 创建配置文件 config.json

配置项可以在GitHub文档上查看：
https://github.com/LinusU/node-appdmg?tab=readme-ov-file#specification

```json
{
  "title": "IcyEasySend",
  "icon": "../../lib/images/icons/app_icon.icns",
  "window": {
    "size": {
      "width": 800,
      "height": 400
    }
  },
  "contents": [
    {
      "x": 250,
      "y": 150,
      "type": "file",
      "path": "../../build/macos/Build/Products/Release/IcyEasySend.app"
    },
    {
      "x": 550,
      "y": 150,
      "type": "link",
      "path": "/Applications"
    }
  ]
}
```

### 3.2 生成 dmg 文件

安装 appdmg 并且构建：

```shell
npm install -g appdmg
cd installers/macOS
mkdir Output
appdmg config.json Output/IcyEasySend-macOS-v1.2.1.dmg
```








