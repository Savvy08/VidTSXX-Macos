#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "Очистка кэша сборки и временных файлов VidTSX..."

rm -rf .build
rm -rf tmp
rm -rf build

echo "Кэш полностью удален. Диск чист."
