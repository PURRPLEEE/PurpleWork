tart · SH
Copier

#!/bin/bash
# ============================================================
#  ANIMATOR V2 — vast.ai on_start.sh — ФИНАЛЬНАЯ ВЕРСИЯ
# ============================================================
 
LOG_FILE="/workspace/animator_setup.log"
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
GITHUB_RAW="https://raw.githubusercontent.com/PURRPLEEE/PurpleWork/main/animator-v2"
GITHUB_ZIP_URL="https://github.com/PURRPLEEE/PurpleWork/releases/latest/download/custom_nodes.zip"
TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"
HF_TOKEN="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"
 
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
    echo "[ERROR] ComfyUI не найден!"
    exit 1
fi
 
# ============================================================
# ШАГ 1: Снимаем security restriction
# ============================================================
echo "[SECURITY] Снимаем ограничения Manager..."
mkdir -p "$COMFYUI_DIR/user/default"
cat > "$COMFYUI_DIR/user/default/comfy.settings.json" << 'EOF'
{
    "Comfy.Manager.GitHubStatsCache": 0,
    "Comfy.Manager.SecurityLevel": "weak"
}
EOF
echo "[OK] Security level = weak"
 
# ============================================================
# ШАГ 2: Custom Nodes из ZIP
# ============================================================
echo "[1/6] Скачиваем custom_nodes.zip..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP" && echo "[OK] Скачан" || { echo "[ERROR] ZIP не скачан"; exit 1; }
 
echo "[2/6] Распаковываем и копируем ноды..."
rm -rf "$TMP_EXTRACT"
mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
 
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
echo "[OK] Ноды скопированы"
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"
 
# ============================================================
# ШАГ 3: Дополнительные ноды через git
# ============================================================
echo "[3/6] Устанавливаем дополнительные ноды..."
cd "$CUSTOM_NODES_DIR"
 
if [ ! -d "ComfyUI-WanVideoWrapper" ]; then
    GIT_TERMINAL_PROMPT=0 git clone -q https://github.com/kijai/ComfyUI-WanVideoWrapper 2>/dev/null || true
    [ -f "ComfyUI-WanVideoWrapper/requirements.txt" ] && /venv/main/bin/pip install -q -r ComfyUI-WanVideoWrapper/requirements.txt || true
    echo "[OK] WanVideoWrapper"
fi
 
if [ ! -d "ComfyUI-KJNodes" ]; then
    GIT_TERMINAL_PROMPT=0 git clone -q https://github.com/kijai/ComfyUI-KJNodes 2>/dev/null || true
    [ -f "ComfyUI-KJNodes/requirements.txt" ] && /venv/main/bin/pip install -q -r ComfyUI-KJNodes/requirements.txt || true
    echo "[OK] KJNodes"
fi
 
if [ ! -d "rgthree-comfy" ]; then
    GIT_TERMINAL_PROMPT=0 git clone -q https://github.com/rgthree/rgthree-comfy 2>/dev/null || true
    echo "[OK] rgthree-comfy"
fi
 
# ============================================================
# ШАГ 4: pip зависимости всех нод
# ============================================================
echo "[4/6] pip install зависимости нод..."
/venv/main/bin/pip install -q opencv-python imageio-ffmpeg
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  → $(basename $d)"
        /venv/main/bin/pip install -q -r "$d/requirements.txt" || true
    fi
done
echo "[OK] Зависимости установлены"
 
# ============================================================
# ШАГ 5: Скачиваем ВСЕ модели
# ============================================================
echo "[5/6] Скачиваем модели..."
 
# Хелпер — скачивает только если файл не существует или пустой
dl() {
    local url="$1"
    local path="$2"
    local token="${3:-}"
    if [ -f "$path" ] && [ "$(stat -c%s "$path")" -gt 1000000 ]; then
        echo "  [SKIP] $(basename $path)"
        return
    fi
    echo "  [DL] $(basename $path)..."
    mkdir -p "$(dirname $path)"
    if [ -n "$token" ]; then
        wget -q --show-progress --header="Authorization: Bearer $token" "$url" -O "$path" && echo "  [OK]" || echo "  [WARN] Ошибка скачивания"
    else
        wget -q --show-progress "$url" -O "$path" && echo "  [OK]" || echo "  [WARN] Ошибка скачивания"
    fi
}
 
# Основная модель WAN (16GB)
dl "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
   "$COMFYUI_DIR/models/diffusion_models/WanModel.safetensors" "$HF_TOKEN"
 
# VAE
dl "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
   "$COMFYUI_DIR/models/vae/vae.safetensors" "$HF_TOKEN"
 
# CLIP Vision
dl "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
   "$COMFYUI_DIR/models/clip_vision/klip_vision.safetensors" "$HF_TOKEN"
 
# Text Encoder
dl "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
   "$COMFYUI_DIR/models/text_encoders/text_enc.safetensors" "$HF_TOKEN"
 
# ControlNet (правильный URL — без /Uni3C/)
dl "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_Uni3C_controlnet_fp16.safetensors" \
   "$COMFYUI_DIR/models/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors" "$HF_TOKEN"
 
# LoRA: light
dl "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
   "$COMFYUI_DIR/models/loras/light.safetensors" "$HF_TOKEN"
 
# LoRA: WanPusa
dl "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
   "$COMFYUI_DIR/models/loras/WanPusa.safetensors" "$HF_TOKEN"
 
# ============================================================
# ONNX модели — кладём ТОЛЬКО в detection/ (правильный путь!)
# Нода ComfyUI-WanAnimatePreprocess ищет именно там
# ============================================================
mkdir -p "$COMFYUI_DIR/models/detection"
 
# YOLOv10m — скачиваем с GitHub (не требует токена)
dl "https://github.com/THU-MIG/yolov10/releases/download/v1.1/yolov10m.onnx" \
   "$COMFYUI_DIR/models/detection/yolov10m.onnx"
 
# ViTPose — скачиваем с JunkyByte (с токеном)
# Размер ~128MB, формат Large (384x288 input — именно то что ожидает нода)
dl "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" \
   "$COMFYUI_DIR/models/detection/vitpose_h_wholebody_model.onnx" "$HF_TOKEN"
 
echo "[OK] Все модели скачаны"
 
# ============================================================
# ШАГ 6: Workflow
# ============================================================
echo "[6/6] Скачиваем workflow..."
mkdir -p "$COMFYUI_DIR/user/default/workflows"
wget -q "$GITHUB_RAW/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json" && \
    echo "[OK] Workflow сохранён" || echo "[WARN] Workflow не скачан"
 
# ============================================================
# Перезапуск ComfyUI
# ============================================================
echo "[RESTART] Перезапускаем ComfyUI..."
supervisorctl restart comfyui 2>/dev/null || true
sleep 3
rm -f /.provisioning
 
echo ""
echo "=============================================="
echo " ✅ ANIMATOR V2 готов! [$(date)]"
echo " Лог: $LOG_FILE"
echo "=============================================="
 