#!/usr/bin/env bash
# Fix common Flutter-on-WSL issues (China network + Windows PATH pollution).
set -euo pipefail

echo "[1/4] Stop stuck Flutter processes and remove startup lock..."
pkill -f '/home/pan/flutter/bin/flutter' 2>/dev/null || true
pkill -f 'dartvm.*flutter_tools' 2>/dev/null || true
rm -f "$HOME/flutter/bin/cache/lockfile"

echo "[2/4] Use Gitee mirror for Flutter git remote (GitHub is slow/blocked)..."
if [ -d "$HOME/flutter/.git" ]; then
  git -C "$HOME/flutter" remote set-url origin https://gitee.com/mirrors/Flutter.git
  git -C "$HOME/flutter" remote -v
fi

echo "[3/4] Ensure ~/.bashrc has Linux Flutter + China mirrors..."
MARKER="# icy-easy-send flutter wsl"
if ! grep -q "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# icy-easy-send flutter wsl
export PATH="$HOME/flutter/bin:$HOME/.cargo/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
EOF
fi

echo "[4/4] Disable Windows PATH injection in WSL (requires: wsl --shutdown from Windows)..."
if [ "$(id -u)" -eq 0 ]; then
  if ! grep -q 'appendWindowsPath' /etc/wsl.conf 2>/dev/null; then
    printf '\n[interop]\nappendWindowsPath = false\n' >> /etc/wsl.conf
  fi
  echo "Updated /etc/wsl.conf. Run 'wsl --shutdown' in Windows PowerShell, then reopen Ubuntu."
else
  echo "Run as root to update /etc/wsl.conf:"
  echo "  sudo bash $0"
fi

echo
echo "Now run in a NEW Ubuntu terminal:"
echo "  source ~/.bashrc"
echo "  which flutter    # must be /home/pan/flutter/bin/flutter"
echo "  flutter --version"
echo
echo "First 'flutter --version' may pause ~1-5 min at 'Got dependencies.' while compiling flutter_tools."
