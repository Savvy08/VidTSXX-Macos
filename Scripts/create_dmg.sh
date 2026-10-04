#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Отмонтировать старые тома VidTSX если есть
for m in $(hdiutil info | grep '/Volumes/VidTSX' | awk '{print $1}'); do
    hdiutil detach "$m" -force 2>/dev/null || true
done

echo "Шаг 1: Сборка актуального автономного бандла VidTSX.app..."
./Scripts/build_app.sh

echo "Шаг 2: Генерация белого фона со стрелкой..."
python3 Scripts/generate_dmg_background.py

echo "Шаг 3: Подготовка содержимого для DMG..."
DMG_STAGING="./build/dmg_staging"
FINAL_DMG="./build/VidTSX.dmg"
TMP_DMG="./build/tmp_rw.dmg"

rm -rf "$DMG_STAGING" "$TMP_DMG" "$FINAL_DMG"
mkdir -p "$DMG_STAGING/.background"

# 1. Копирование приложения
cp -R "./build/VidTSX.app" "$DMG_STAGING/"

# 2. Ярлык на Applications
ln -s /Applications "$DMG_STAGING/Applications"

# 3. Фон окна DMG
cp "Resources/dmg_background.png" "$DMG_STAGING/.background/dmg_background.png"
chmod -R 755 "$DMG_STAGING/.background"
chmod 644 "$DMG_STAGING/.background/dmg_background.png"

echo "Шаг 4: Создание временного DMG для настройки Finder..."
hdiutil create -ov -srcfolder "$DMG_STAGING" -volname "VidTSX" -format UDRW "$TMP_DMG"

MOUNT_INFO=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG")
DEV_NAME=$(echo "$MOUNT_INFO" | egrep '^/dev/' | head -n 1 | awk '{print $1}')
VOLUME_PATH=$(echo "$MOUNT_INFO" | grep '/Volumes/' | awk -F '/Volumes/' '{print "/Volumes/" $2}')

echo "Примонтирован том $VOLUME_PATH на $DEV_NAME"

echo "Шаг 5: Оформление окна установщика через AppleScript..."
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "VidTSX"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {250, 150, 910, 590}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 130
        set text size of viewOptions to 12
        try
            set background picture of viewOptions to file ".background:dmg_background.png" of disk "VidTSX"
        end try
        try
            set background picture of viewOptions to (POSIX file "$VOLUME_PATH/.background/dmg_background.png" as alias)
        end try
        set position of item "VidTSX.app" of container window to {165, 215}
        set position of item "Applications" of container window to {495, 215}
        try
            set extension hidden of item "VidTSX.app" of container window to true
        end try
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT

sync
sleep 1

echo "Шаг 6: Отмонтирование и упаковка в сжатый финальный DMG (UDZO)..."
hdiutil detach "$DEV_NAME" -force || true

hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

rm -rf "$TMP_DMG" "$DMG_STAGING"

echo "Готово! Финальный автономный установщик создан:"
ls -lh "$FINAL_DMG"
