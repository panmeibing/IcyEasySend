# 构建 Linux 安装包

Flutter 的 Linux 桌面版**无法在 Windows 原生环境直接交叉编译**，需要在 **WSL2 + Ubuntu**（或 Linux 虚拟机/实体机）中完成。

本文档说明在本项目中编译 Release 版本，并打包为 **tar.gz 便携包** 或 **deb 安装包** 的完整流程。

---

## 1. 环境要求

- Windows 11 + WSL2（推荐 Ubuntu 24.04）
- 磁盘空间：建议预留 5 GB 以上（Flutter SDK + 编译产物）

### 1.1 安装系统依赖（仅需一次）

在 Ubuntu 终端中执行：

```bash
sudo apt update
sudo apt install -y \
  unzip curl git \
  clang cmake ninja-build pkg-config patchelf \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsecret-1-dev libayatana-appindicator3-dev \
  dpkg
```

### 1.2 安装 Linux 版 Flutter（仅需一次）

> **重要**：WSL 中必须使用 Linux 版 Flutter（`~/flutter`），**不要**使用 Windows 路径下的 Flutter（如 `/mnt/d/kaifa/flutter`），否则会出现 `$'\r': command not found` 等错误。

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter

# 写入 ~/.bashrc
cat >> ~/.bashrc <<'EOF'
export PATH="$HOME/flutter/bin:$HOME/.cargo/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
EOF

source ~/.bashrc
flutter --version
```

**国内网络建议**：将 Flutter 的 git 源改为 Gitee（镜像不包含 GitHub，否则 `flutter --version` 可能长时间无响应）：

```bash
git -C ~/flutter remote set-url origin https://gitee.com/mirrors/Flutter.git
```

**建议关闭 WSL 对 Windows PATH 的注入**（避免误用 Windows 版 Flutter）。在 Windows PowerShell 中：

```powershell
wsl --shutdown
```

确认 `/etc/wsl.conf` 中包含：

```ini
[interop]
appendWindowsPath = false
```

修改后需再次执行 `wsl --shutdown` 并重新打开 Ubuntu。

### 1.3 安装 Rust（仅需一次）

本项目依赖 `super_native_extensions`，Linux 编译需要 Rust：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustc --version
```

### 1.4 验证环境

```bash
source ~/.bashrc
which flutter          # 应输出: /home/<用户名>/flutter/bin/flutter
flutter doctor -v      # Linux toolchain 无 ❌ 即可
```

若环境异常，可运行诊断/修复脚本（见文末「辅助脚本」）。

---

## 2. 编译 Release 版本

进入项目目录（Windows 盘符在 WSL 中一般为 `/mnt/f/...`）：

```bash
cd /mnt/f/repository/icy-easy-send

export PATH="$HOME/flutter/bin:$HOME/.cargo/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter pub get
flutter build linux --release
```

编译成功后，可运行目录位于：

```
build/linux/x64/release/bundle/
├── IcyEasySend      # 主程序
├── data/            # 资源与 flutter_assets
└── lib/             # 动态库
```

本地试运行（需 WSLg 或 Linux 桌面环境）：

```bash
cd build/linux/x64/release/bundle
./IcyEasySend
```

---

## 3. 打包

所有打包脚本位于 `installers/Linux/`，产物默认输出到 `installers/Linux/dist/`。

### 3.1 tar.gz 便携包（解压即用）

```bash
bash installers/Linux/package_release.sh [版本号]
# 示例
bash installers/Linux/package_release.sh 1.3.0
```

生成文件：

```
installers/Linux/dist/IcyEasySend-linux-x64-v1.3.0.tar.gz
```

在目标 Linux 机器上使用：

```bash
tar -xzf IcyEasySend-linux-x64-v1.3.0.tar.gz
cd bundle
./IcyEasySend
```

### 3.2 deb 安装包（推荐分发 Ubuntu/Debian）

```bash
bash installers/Linux/build_deb.sh [版本号] [修订号]
# 示例
bash installers/Linux/build_deb.sh 1.3.0 1
```

生成文件：

```
installers/Linux/dist/icy-easy-send_1.3.0-1_amd64.deb
```

在目标机器上安装：

```bash
sudo dpkg -i icy-easy-send_1.3.0-1_amd64.deb
sudo apt -f install   # 若提示缺少依赖
```

安装后：

- 命令行启动：`icy-easy-send`
- 应用菜单：搜索 **Icy Easy Send**
- 安装路径：`/opt/IcyEasySend/`

卸载：

```bash
sudo apt remove icy-easy-send
```

---

## 4. 一键流程（汇总）

每次发版可按以下顺序执行（假设已在 WSL 中配置好环境）：

```bash
cd /mnt/f/repository/icy-easy-send
source ~/.bashrc

flutter pub get
flutter build linux --release

bash installers/Linux/package_release.sh 1.3.0
bash installers/Linux/build_deb.sh 1.3.0 1
```

---

## 5. 常见问题

### `flutter --version` 或 `flutter pub get` 卡住不动

1. 确认 `which flutter` 指向 `~/flutter/bin/flutter`，而非 `/mnt/d/...`
2. 首次运行可能在 `Got dependencies.` 后**静默编译 flutter_tools**，需等待 1～5 分钟
3. 清理残留锁：`pkill -f flutter; rm -f ~/flutter/bin/cache/lockfile`
4. 确认已切换 Gitee git 源（见 1.2 节）

### `dpkg-deb: control directory has bad permissions 777`

不要在 Windows 挂载盘（`/mnt/f/...`）上直接作为 deb  staging 目录。`build_deb.sh` 已改为在 `/tmp` 中打包，请使用脚本而非手动 `dpkg-deb`。

### 编译很慢

项目放在 `/mnt/f/...` 时 I/O 较慢。若经常编译，可将仓库 clone 到 WSL 原生目录（如 `~/projects/icy-easy-send`）再构建。

### 目标机器缺少 GTK

```bash
sudo apt install libgtk-3-0
```

---

## 6. 辅助脚本

| 脚本 | 用途 |
|------|------|
| `package_release.sh` | 将 bundle 打包为 tar.gz |
| `build_deb.sh` | 将 bundle 打包为 deb 安装包 |
| `wsl_flutter_fix.sh` | 修复 WSL 中 Flutter PATH / Gitee / lockfile 等常见问题 |
| `wsl_flutter_diag.sh` | 诊断 Flutter 在 WSL 中的运行状态 |

运行脚本前若出现 `$'\r': command not found`，先转换换行符：

```bash
sed -i 's/\r$//' installers/Linux/*.sh
```

---

## 7. 产物目录说明

```
installers/Linux/
├── readme.md              # 本文档
├── build_deb.sh           # deb 打包脚本
├── package_release.sh     # tar.gz 打包脚本
├── linux_bundle_lib.sh    # 架构/bundle 检测（供脚本复用）
├── wsl_flutter_fix.sh     # 环境修复脚本
├── wsl_flutter_diag.sh    # 环境诊断脚本
└── dist/                  # 打包输出目录（tar.gz / deb）
```

## 8. GitHub Actions 自动发版

CI 配置见 [`.github/RELEASE_SETUP.md`](../../.github/RELEASE_SETUP.md)。打 tag（如 `v1.3.0`）后会自动构建 Linux / Windows / macOS / Android 安装包，并创建 **Draft Release**，需手动补充 Release Notes 后发布。
