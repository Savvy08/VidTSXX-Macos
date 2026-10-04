#!/bin/bash
set -e

echo "Компиляция VidTSX для Apple Silicon (Release arm64)..."
cd "$(dirname "$0")/.."

swift build -c release --arch arm64

APP_NAME="VidTSX"
APP_DIR="./build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Формирование бандла $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp .build/arm64-apple-macosx/release/$APP_NAME "$MACOS_DIR/$APP_NAME"

cp Info.plist "$CONTENTS_DIR/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -d "Resources/web" ]; then
    cp -R Resources/web "$RESOURCES_DIR/"
fi

if [ ! -f "Resources/runtime/bin/node" ]; then
    echo "Подготовка автономного рантайма Node.js..."
    mkdir -p Resources/runtime/bin
    curl -sL https://nodejs.org/dist/v20.18.0/node-v20.18.0-darwin-arm64.tar.gz | tar -xz -C Resources/runtime --strip-components=1 node-v20.18.0-darwin-arm64/bin/node
    chmod +x Resources/runtime/bin/node
fi

if [ -d "Resources/runtime" ]; then
    cp -R Resources/runtime "$RESOURCES_DIR/"
fi

echo "Подпись приложения..."
codesign --force --deep --sign - "$APP_DIR"

echo "Готово! Приложение $APP_NAME.app создано в: $APP_DIR"
