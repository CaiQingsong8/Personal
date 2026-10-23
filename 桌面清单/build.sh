#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUILD_ROOT="$SCRIPT_DIR/build"
APP_ROOT="$BUILD_ROOT/桌面清单.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET="$BUILD_ROOT/AppIcon.iconset"
SDK_ROOT="${DESKFLOW_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
SDK_NAME="${SDK_ROOT:t}"
MODULE_CACHE="$BUILD_ROOT/ModuleCache-$SDK_NAME"
CLANG_MODULE_CACHE="$BUILD_ROOT/ClangModuleCache-$SDK_NAME"

mkdir -p "$MACOS" "$RESOURCES" "$ICONSET" "$MODULE_CACHE" "$CLANG_MODULE_CACHE"

SOURCES=(
  "$SCRIPT_DIR/Models.swift"
  "$SCRIPT_DIR/AppStore.swift"
  "$SCRIPT_DIR/CalendarSyncService.swift"
  "$SCRIPT_DIR/ReminderSyncService.swift"
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

swiftc -sdk "$SDK_ROOT" -module-cache-path "$MODULE_CACHE" \
  -clang-scanner-module-cache-path "$CLANG_MODULE_CACHE" -Xcc "-fmodules-cache-path=$CLANG_MODULE_CACHE" \
  -O -parse-as-library -target x86_64-apple-macosx13.0 \
  "${SOURCES[@]}" "${FRAMEWORKS[@]}" \
  -o "$BUILD_ROOT/DeskFlow-x86_64"

swiftc -sdk "$SDK_ROOT" -module-cache-path "$MODULE_CACHE" \
  -clang-scanner-module-cache-path "$CLANG_MODULE_CACHE" -Xcc "-fmodules-cache-path=$CLANG_MODULE_CACHE" \
  -O -parse-as-library -target arm64-apple-macosx13.0 \
  "${SOURCES[@]}" "${FRAMEWORKS[@]}" \
  -o "$BUILD_ROOT/DeskFlow-arm64"

lipo -create "$BUILD_ROOT/DeskFlow-x86_64" "$BUILD_ROOT/DeskFlow-arm64" \
  -output "$MACOS/DeskFlow"

swiftc -sdk "$SDK_ROOT" -module-cache-path "$MODULE_CACHE" \
  -clang-scanner-module-cache-path "$CLANG_MODULE_CACHE" -Xcc "-fmodules-cache-path=$CLANG_MODULE_CACHE" \
  "$SCRIPT_DIR/IconGenerator.swift" -framework AppKit -o "$BUILD_ROOT/icon-generator"
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
FALLBACK_ICON="$BUILD_ROOT/AppIcon-fallback.icns"
if [[ -n "${DESKFLOW_FALLBACK_ICON:-}" && -f "$DESKFLOW_FALLBACK_ICON" ]]; then
  cp "$DESKFLOW_FALLBACK_ICON" "$FALLBACK_ICON"
elif [[ -f "$RESOURCES/AppIcon.icns" ]]; then
  cp "$RESOURCES/AppIcon.icns" "$FALLBACK_ICON"
fi
if ! iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"; then
  if [[ -f "$FALLBACK_ICON" ]]; then
    cp "$FALLBACK_ICON" "$RESOURCES/AppIcon.icns"
  else
    echo "图标集生成失败，且没有提供可复用的现有 AppIcon.icns" >&2
    exit 1
  fi
fi

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
