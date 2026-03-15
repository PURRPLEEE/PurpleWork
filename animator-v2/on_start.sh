#!/bin/bash
# ============================================================
#  ANIMATOR V2 — vast.ai on_start.sh
#  Этот скрипт запускается АВТОМАТИЧЕСКИ при старте инстанса
#  Вставить в поле "On-start script" при создании шаблона
# ============================================================

LOG_FILE="/workspace/animator_setup.log"
GITHUB_RAW="https://raw.githubusercontent.com/YOUR_USERNAME/animator-v2/main"
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

exec > >(tee -a "$LOG_FILE") 2>&1

echo ""
echo "=============================================="
echo " ANIMATOR V2 — Auto Setup [$(date)]"
echo "=============================================="

# Ждём пока ComfyUI директория появится
echo "[WAIT] Ждём /workspace/ComfyUI..."
for i in $(seq 1 30); do
    if [ -d "$COMFYUI_DIR" ]; then
        echo "[OK] ComfyUI найден!"
        break
    fi
    sleep 5
done

# Скачиваем ZIP с custom nodes
GITHUB_ZIP_URL="https://github.com/YOUR_USERNAME/animator-v2/releases/latest/download/custom_nodes.zip"
TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"

echo "[1/6] Скачиваем custom_nodes.zip..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP" && echo "[OK] Скачан" || { echo "[ERROR] Не удалось скачать ZIP"; exit 1; }

echo "[2/6] Распаковываем..."
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
echo "[OK] Распаковано"

echo "[3/6] Копируем в custom_nodes..."
mkdir -p "$CUSTOM_NODES_DIR"
INNER=$(ls "$TMP_EXTRACT")
COUNT=$(echo "$INNER" | wc -l)
if [ "$COUNT" -eq 1 ] && [ -d "$TMP_EXTRACT/$INNER" ]; then
    cp -r "$TMP_EXTRACT/$INNER"/. "$CUSTOM_NODES_DIR/"
else
    cp -r "$TMP_EXTRACT"/. "$CUSTOM_NODES_DIR/"
fi
echo "[OK] Скопировано"
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"

echo "[4/6] pip install ComfyUI requirements..."
pip install -q -r "$COMFYUI_DIR/requirements.txt"
echo "[OK] Done"

echo "[5/6] pip install custom nodes requirements..."
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  → $(basename $d)"
        pip install -q -r "$d/requirements.txt"
    fi
done
echo "[OK] Все зависимости установлены"

# Скачиваем workflow JSON в папку ComfyUI
echo "[6/6] Скачиваем workflow..."
wget -q "$GITHUB_RAW/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json" && \
    echo "[OK] Workflow сохранён" || echo "[WARN] Workflow не скачан (не критично)"

echo "[RESTART] Перезапускаем ComfyUI..."
supervisorctl restart comfyui

echo ""
echo "=============================================="
echo " ✅ ANIMATOR V2 готов! [$(date)]"
echo " Лог: $LOG_FILE"
echo "=============================================="
