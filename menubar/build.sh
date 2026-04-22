#!/bin/bash
# 編譯 NAS MenuBar App（arm64）
# 用法：./build.sh          （編譯到 ./build/）
#       ./build.sh install  （編譯後直接安裝到 /Applications/ 並重啟）
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="NASMenuBar"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"

G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'

echo -e "${Y}▶ 清除舊編譯...${N}"
/bin/rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo -e "${Y}▶ 編譯 Swift...${N}"
swiftc -O -target arm64-apple-macos14 \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  AppDelegate.swift ConnectionManager.swift

cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
echo -e "${G}✓ 編譯完成：$APP_BUNDLE${N}"

if [ "${1:-}" = "install" ]; then
  echo -e "${Y}▶ 安裝到 /Applications/...${N}"
  killall "$APP_NAME" 2>/dev/null || true
  killall NASVPNMenuBar 2>/dev/null || true
  /bin/rm -rf "/Applications/${APP_NAME}.app" "/Applications/NASVPNMenuBar.app"
  cp -R "$APP_BUNDLE" /Applications/
  open "/Applications/${APP_NAME}.app"
  echo -e "${G}✓ 已安裝並啟動${N}"
fi
