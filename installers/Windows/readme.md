# 构建 Windows 安装包

## 1.编译

编译生成Windows程序

```shell
flutter build windows --release
```

> 运行结束之后会把文件放在`build\windows\x64\runner\Release\IcyEasySend.exe`

## 2. 打包便携版（zip）

将 Release 目录打包为绿色便携版：

```powershell
flutter build windows --release
pwsh installers/Windows/package_portable.ps1 -Version 1.3.0
```

产物：`installers/Windows/Output/IcyEasySend-windows-v1.3.0-portable.zip`（解压即用，无需安装）

## 3. 打包为安装包

打包成exe安装包，可以使用 `Inno Setup Compiler`，但是可能会被杀软报毒

### 3.1 下载 Inno Setup Compiler

因为`Inno Setup Complier`是免费软件，所以可以直接去它的官网下载安装就好

### 3.2 配置中文

比较新的版本的`Inno Setup Compiler`是不带简体中文包的，需要手动下载
然后将下载的 `ChineseSimplified.isl` 文件复制到`Inno Setup`的安装目录下的`Languages`文件夹中

### 3.3 创建脚本

需要把编译的配置保存到`iss`文件中，比如说保存到`installers/Windows/setup_script.iss`

### 3.4 打包成安装包

在`Inno Setup`界面中，点击菜单栏的`Build` -> `Compile Current Script`

### 3.5 安装包位置

安装包输出到 `installers/Windows/Output/`，文件名为 `IcyEasySend-windows-v1.3.0-setup.exe`。