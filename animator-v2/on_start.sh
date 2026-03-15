#!/bin/bash
# ============================================================
#  ANIMATOR V2 — vast.ai on_start.sh
# ============================================================
 
LOG_FILE="/tmp/animator_setup.log"
GITHUB_ZIP_URL="https://github.com/PURRPLEEE/PurpleWork/releases/latest/download/custom_nodes.zip"
TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"
 
exec > >(tee -a "$LOG_FILE") 2>&1
 
echo ""
echo "=============================================="
echo " ANIMATOR V2 — Auto Setup [$(date)]"
echo "=============================================="
 
# Ищем папку ComfyUI
echo "[WAIT] Ищем ComfyUI..."
COMFYUI_DIR=""
for path in /workspace/ComfyUI /opt/ComfyUI /root/ComfyUI /home/user/ComfyUI; do
    if [ -d "$path" ]; then
        COMFYUI_DIR="$path"
        echo "[OK] ComfyUI найден: $COMFYUI_DIR"
        break
    fi
done
 
if [ -z "$COMFYUI_DIR" ]; then
    echo "[WAIT] Ждём появления ComfyUI..."
    for i in $(seq 1 30); do
        sleep 5
        for path in /workspace/ComfyUI /opt/ComfyUI /root/ComfyUI /home/user/ComfyUI; do
            if [ -d "$path" ]; then
                COMFYUI_DIR="$path"
                echo "[OK] ComfyUI найден: $COMFYUI_DIR"
                break 2
            fi
        done
    done
fi
 
if [ -z "$COMFYUI_DIR" ]; then
    echo "[ERROR] ComfyUI не найден!"
    exit 1
fi
 
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
 
echo "[1/6] Скачиваем custom_nodes.zip..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP" && echo "[OK] Скачан" || { echo "[ERROR] Не удалось скачать ZIP"; exit 1; }
 
echo "[2/6] Распаковываем..."
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
echo "[OK] Распаковано"
 
echo "[3/6] Копируем в custom_nodes..."
mkdir -p "$CUSTOM_NODES_DIR"
if [ -d "$TMP_EXTRACT/nodes" ]; then
    cp -r "$TMP_EXTRACT/nodes"/. "$CUSTOM_NODES_DIR/"
elif [ -d "$TMP_EXTRACT/custom_nodes" ]; then
    cp -r "$TMP_EXTRACT/custom_nodes"/. "$CUSTOM_NODES_DIR/"
else
    INNER=$(ls "$TMP_EXTRACT" | head -1)
    if [ -d "$TMP_EXTRACT/$INNER/nodes" ]; then
        cp -r "$TMP_EXTRACT/$INNER/nodes"/. "$CUSTOM_NODES_DIR/"
    elif [ -d "$TMP_EXTRACT/$INNER" ]; then
        cp -r "$TMP_EXTRACT/$INNER"/. "$CUSTOM_NODES_DIR/"
    else
        cp -r "$TMP_EXTRACT"/. "$CUSTOM_NODES_DIR/"
    fi
fi
echo "[OK] Скопировано"
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"
 
echo "[4/6] pip install зависимости..."
PIP_CMD=""
for pip in /venv/main/bin/pip /usr/bin/pip3 pip3 pip; do
    if command -v $pip &>/dev/null || [ -f "$pip" ]; then
        PIP_CMD=$pip
        break
    fi
done
 
[ -f "$COMFYUI_DIR/requirements.txt" ] && $PIP_CMD install -q -r "$COMFYUI_DIR/requirements.txt" || true
$PIP_CMD install -q opencv-python imageio-ffmpeg || true
echo "[OK] Done"
 
echo "[5/6] pip install custom nodes requirements..."
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  → $(basename $d)"
        $PIP_CMD install -q -r "$d/requirements.txt" || true
    fi
done
echo "[OK] Все зависимости установлены"
 
echo "[6/6] Скачиваем workflow..."
mkdir -p "$COMFYUI_DIR/user/default/workflows"
wget -q "https://raw.githubusercontent.com/PURRPLEEE/PurpleWork/main/animator-v2/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json" && \
    echo "[OK] Workflow сохранён" || echo "[WARN] Workflow не скачан"
 
echo "[RESTART] Перезапускаем ComfyUI..."
supervisorctl restart comfyui 2>/dev/null || \
pkill -f "python.*main.py" 2>/dev/null || true
rm -f /.provisioning 2>/dev/null || true
 
echo ""
echo "=============================================="
echo " ✅ ANIMATOR V2 готов! [$(date)]"
echo " Лог: $LOG_FILE"
echo "=============================================="
 