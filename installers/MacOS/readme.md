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

```shell
# 请将 IcyEasySend.app 替换为你实际的应用名称
# 请将 "IcyHope" 替换为你刚才设置的证书名称（如果名字里有空格，必须加双引号）

codesign --deep --force --verify --verbose \
--sign "IcyHope" \
build/macos/Build/Products/Release/IcyEasySend.app
```

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
appdmg config.json Output/IcyEasySend-installer.dmg
```








