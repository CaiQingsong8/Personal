#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUILD_ROOT="$SCRIPT_DIR/build"
APP_ROOT="$BUILD_ROOT/桌面清单.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET="$BUILD_ROOT/AppIcon.iconset"

mkdir -p "$MACOS" "$RESOURCES" "$ICONSET"

SOURCES=(
  "$SCRIPT_DIR/Models.swift"
  "$SCRIPT_DIR/AppStore.swift"
  "$SCRIPT_DIR/CalendarSyncService.swift"
  "$SCRIPT_DIR/RootView.swift"
  "$SCRIPT_DIR/TaskListView.swift"
  "$SCRIPT_DIR/MonthView.swift"
  "$SCRIPT_DIR/StatsView.swift"
  "$SCRIPT_DIR/DeskFlowApp.swift"
)

FRAMEWORKS=(
  -framework SwiftUI
  -framework AppKit
  -framework EventKit
  -framework UserNotifications
  -framework UniformTypeIdentifiers
)

swiftc -O -parse-as-library -target x86_64-apple-macosx14.0 \
  "${SOURCES[@]}" "${FRAMEWORKS[@]}" \
  -o "$BUILD_ROOT/DeskFlow-x86_64"

swiftc -O -parse-as-library -target arm64-apple-macosx14.0 \
  "${SOURCES[@]}" "${FRAMEWORKS[@]}" \
  -o "$BUILD_ROOT/DeskFlow-arm64"

lipo -create "$BUILD_ROOT/DeskFlow-x86_64" "$BUILD_ROOT/DeskFlow-arm64" \
  -output "$MACOS/DeskFlow"

swiftc "$SCRIPT_DIR/IconGenerator.swift" -framework AppKit -o "$BUILD_ROOT/icon-generator"
"$BUILD_ROOT/icon-generator" "$BUILD_ROOT/icon_1024x1024.png"

sips -z 16 16 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$BUILD_ROOT/icon_1024x1024.png" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$BUILD_ROOT/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"
signed=false
for _ in {1..5}; do
  xattr -cr "$APP_ROOT"
  xattr -d com.apple.FinderInfo "$APP_ROOT" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$APP_ROOT" 2>/dev/null || true
  if codesign --force --deep --sign - "$APP_ROOT" >/dev/null 2>&1; then
    signed=true
    break
  fi
done

if [[ "$signed" != true ]]; then
  echo "无法为应用完成本地签名" >&2
  exit 1
fi

echo "$APP_ROOT"
