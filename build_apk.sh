#!/bin/bash
# 生活追踪 APK 构建脚本
set -e

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export ANDROID_HOME=$HOME/android-sdk
export PATH=/snap/bin:$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

PROJECT_DIR="/mnt/d/flutter_projects/life_tracker"

echo "=== 检查 Flutter 环境 ==="
flutter --version

echo ""
echo "=== 接受 Android 许可 ==="
yes | sdkmanager --licenses 2>/dev/null || true

echo ""
echo "=== 安装依赖 ==="
cd "$PROJECT_DIR"
flutter pub get

echo ""
echo "=== 构建 APK (release) ==="
flutter build apk --release

echo ""
echo "=== 构建完成 ==="
APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo "APK 路径: $APK"
ls -lh "$APK"
