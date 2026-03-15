#!/bin/bash
LOG_FILE="/workspace/animator_setup.log"
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
GITHUB_RAW="https://raw.githubusercontent.com/PURRPLEEE/PurpleWork/main/animator-v2"
GITHUB_ZIP_URL="https://github.com/PURRPLEEE/PurpleWork/releases/latest/download/custom_nodes.zip"
TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo " ANIMATOR V2 — Auto Setup [$(date)]"
echo "=============================================="

# Ждём ComfyUI до 5 минут
echo "[WAIT] Ждём /workspace/ComfyUI..."
for i in $(seq 1 60); do
    if [ -d "$COMFYUI_DIR/custom_nodes" ]; then
        echo "[OK] ComfyUI найден!"
        break
    fi
    sleep 5
done

if [ ! -d "$COMFYUI_DIR/custom_nodes" ]; then
    echo "[ERROR] ComfyUI не найден после ожидания!"
    exit 1
fi

# Снимаем security restriction для Manager
echo "[SECURITY] Снимаем ограничения Manager..."
mkdir -p "$COMFYUI_DIR/user/default"
cat > "$COMFYUI_DIR/user/default/comfy.settings.json" << 'EOF'
{
    "Comfy.Manager.GitHubStatsCache": 0,
    "Comfy.Manager.SecurityLevel": "weak"
}
EOF
echo "[OK] Security level установлен"

# Скачиваем и устанавливаем ноды
echo "[1/5] Скачиваем custom_nodes.zip..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP" && echo "[OK] Скачан" || { echo "[ERROR] Не удалось скачать ZIP"; exit 1; }

echo "[2/5] Распаковываем..."
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
echo "[OK] Распаковано"

echo "[3/5] Копируем в custom_nodes..."
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

echo "[4/5] pip install зависимости..."
/venv/main/bin/pip install -q opencv-python imageio-ffmpeg
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  → $(basename $d)"
        /venv/main/bin/pip install -q -r "$d/requirements.txt" || true
    fi
done
echo "[OK] Зависимости установлены"

echo "[5/5] Скачиваем workflow..."
mkdir -p "$COMFYUI_DIR/user/default/workflows"
wget -q "$GITHUB_RAW/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json" && \
    echo "[OK] Workflow сохранён" || echo "[WARN] Workflow не скачан"

echo "[RESTART] Перезапускаем ComfyUI..."
supervisorctl restart comfyui 2>/dev/null || true

echo "=============================================="
echo " ✅ ANIMATOR V2 готов! [$(date)]"
echo "=============================================="