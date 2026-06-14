#!/usr/bin/env bash
set -x
export PATH="$HOME/flutter/bin:$PATH"
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn

echo "=== which flutter ==="
which flutter
file "$(which flutter)"

echo "=== lockfile ==="
ls -la "$HOME/flutter/bin/cache/lockfile" 2>&1
lsof "$HOME/flutter/bin/cache/lockfile" 2>/dev/null || true

echo "=== flutter --version (60s timeout) ==="
timeout 60 flutter --version -v 2>&1 | tail -50
echo "flutter --version exit: $?"

echo "=== pub get (90s timeout) ==="
cd /mnt/f/repository/icy-easy-send || exit 1
timeout 90 flutter pub get -v 2>&1 | tail -30
echo "pub get exit: $?"
