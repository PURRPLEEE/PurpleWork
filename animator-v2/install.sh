#!/bin/bash
# ============================================================
#  ANIMATOR V2 — Custom Nodes Installer
#  Скачивает ZIP с GitHub и устанавливает все зависимости
# ============================================================

set -e

GITHUB_ZIP_URL="https://github.com/YOUR_USERNAME/animator-v2/releases/latest/download/custom_nodes.zip"
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"

echo ""
echo "================================================"
echo "   ANIMATOR V2 — Установка Custom Nodes"
echo "================================================"
echo ""

# 1. Скачиваем ZIP
echo "[1/5] Скачиваем архив custom nodes с GitHub..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP"
echo "      ✓ Архив скачан"

# 2. Распаковываем
echo "[2/5] Распаковываем архив..."
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
echo "      ✓ Распаковано"

# 3. Копируем папки в custom_nodes
echo "[3/5] Копируем папки в $CUSTOM_NODES_DIR ..."
mkdir -p "$CUSTOM_NODES_DIR"
# Копируем содержимое: если в архиве есть папка-обёртка — берём её содержимое
INNER=$(ls "$TMP_EXTRACT")
COUNT=$(echo "$INNER" | wc -l)
if [ "$COUNT" -eq 1 ] && [ -d "$TMP_EXTRACT/$INNER" ]; then
    cp -r "$TMP_EXTRACT/$INNER"/. "$CUSTOM_NODES_DIR/"
else
    cp -r "$TMP_EXTRACT"/. "$CUSTOM_NODES_DIR/"
fi
echo "      ✓ Custom nodes скопированы"

# 4. Устанавливаем зависимости ComfyUI
echo "[4/5] Устанавливаем зависимости ComfyUI..."
pip install -q -r "$COMFYUI_DIR/requirements.txt"
echo "      ✓ requirements.txt ComfyUI установлены"

# 5. Устанавливаем зависимости каждого custom node
echo "[5/5] Устанавливаем зависимости custom nodes..."
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "      → $(basename $d)"
        pip install -q -r "$d/requirements.txt"
    fi
done
echo "      ✓ Все зависимости установлены"

# Чистим временные файлы
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"

echo ""
echo "================================================"
echo "   ✅ Установка завершена!"
echo "   Перезапусти ComfyUI: supervisorctl restart comfyui"
echo "================================================"
echo ""
