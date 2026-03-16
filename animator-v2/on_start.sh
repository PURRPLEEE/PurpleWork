#!/bin/bash
# ============================================================
#  ANIMATOR V2 — vast.ai on_start.sh
#  Автоматическая установка нод + скачивание всех моделей
# ============================================================

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
    echo "[ERROR] ComfyUI не найден!"
    exit 1
fi

# ============================================================
# ШАГ 1: Custom Nodes из ZIP
# ============================================================
echo "[1/7] Скачиваем custom_nodes.zip..."
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP" && echo "[OK] Скачан" || { echo "[ERROR] Не удалось скачать ZIP"; exit 1; }

echo "[2/7] Распаковываем и копируем..."
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
echo "[OK] Custom nodes скопированы"
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"

# ============================================================
# ШАГ 2: Дополнительные ноды через git clone
# ============================================================
echo "[3/7] Устанавливаем WanVideoWrapper и KJNodes..."
cd "$CUSTOM_NODES_DIR"

if [ ! -d "ComfyUI-WanVideoWrapper" ]; then
    git clone -q https://github.com/kijai/ComfyUI-WanVideoWrapper
    /venv/main/bin/pip install -q -r ComfyUI-WanVideoWrapper/requirements.txt || true
    echo "[OK] WanVideoWrapper"
fi

if [ ! -d "ComfyUI-KJNodes" ]; then
    git clone -q https://github.com/kijai/ComfyUI-KJNodes
    /venv/main/bin/pip install -q -r ComfyUI-KJNodes/requirements.txt || true
    echo "[OK] KJNodes"
fi

# ============================================================
# ШАГ 3: pip зависимости всех нод
# ============================================================
echo "[4/7] pip install зависимости нод..."
/venv/main/bin/pip install -q opencv-python imageio-ffmpeg
for d in "$CUSTOM_NODES_DIR"/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  → $(basename $d)"
        /venv/main/bin/pip install -q -r "$d/requirements.txt" || true
    fi
done
echo "[OK] Зависимости установлены"

# ============================================================
# ШАГ 4: Скачиваем ВСЕ модели
# ============================================================
echo "[5/7] Скачиваем модели..."

# --- Основная модель WAN ---
mkdir -p "$COMFYUI_DIR/models/diffusion_models"
if [ ! -f "$COMFYUI_DIR/models/diffusion_models/WanModel.safetensors" ]; then
    echo "  → WanModel (16GB)..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
        -O "$COMFYUI_DIR/models/diffusion_models/WanModel.safetensors"
    echo "[OK] WanModel"
fi

# --- VAE ---
mkdir -p "$COMFYUI_DIR/models/vae"
if [ ! -f "$COMFYUI_DIR/models/vae/vae.safetensors" ]; then
    echo "  → VAE..."
    wget -q --show-progress \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
        -O "$COMFYUI_DIR/models/vae/vae.safetensors"
    echo "[OK] VAE"
fi

# --- CLIP Vision ---
mkdir -p "$COMFYUI_DIR/models/clip_vision"
if [ ! -f "$COMFYUI_DIR/models/clip_vision/klip_vision.safetensors" ]; then
    echo "  → CLIP Vision..."
    wget -q --show-progress \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
        -O "$COMFYUI_DIR/models/clip_vision/klip_vision.safetensors"
    echo "[OK] CLIP Vision"
fi

# --- Text Encoder ---
mkdir -p "$COMFYUI_DIR/models/text_encoders"
if [ ! -f "$COMFYUI_DIR/models/text_encoders/text_enc.safetensors" ]; then
    echo "  → Text Encoder..."
    wget -q --show-progress \
        "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
        -O "$COMFYUI_DIR/models/text_encoders/text_enc.safetensors"
    echo "[OK] Text Encoder"
fi

# --- ControlNet ---
mkdir -p "$COMFYUI_DIR/models/controlnet"
if [ ! -f "$COMFYUI_DIR/models/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors" ]; then
    echo "  → ControlNet Uni3C..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Uni3C/Wan21_Uni3C_controlnet_fp16.safetensors" \
        -O "$COMFYUI_DIR/models/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors"
    echo "[OK] ControlNet"
fi

# --- LoRA: light ---
mkdir -p "$COMFYUI_DIR/models/loras"
if [ ! -f "$COMFYUI_DIR/models/loras/light.safetensors" ]; then
    echo "  → LoRA: light..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
        -O "$COMFYUI_DIR/models/loras/light.safetensors"
    echo "[OK] LoRA light"
fi

# --- LoRA: WanPusa ---
if [ ! -f "$COMFYUI_DIR/models/loras/WanPusa.safetensors" ]; then
    echo "  → LoRA: WanPusa..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
        -O "$COMFYUI_DIR/models/loras/WanPusa.safetensors"
    echo "[OK] LoRA WanPusa"
fi

# --- Detection Models ---
mkdir -p "$COMFYUI_DIR/models/onnx"
if [ ! -f "$COMFYUI_DIR/models/onnx/yolov10m.onnx" ]; then
    echo "  → YOLOv10m..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/yolov10m.onnx" \
        -O "$COMFYUI_DIR/models/onnx/yolov10m.onnx"
    echo "[OK] yolov10m"
fi

if [ ! -f "$COMFYUI_DIR/models/onnx/vitpose_h_wholebody_model.onnx" ]; then
    echo "  → ViTPose..."
    wget -q --show-progress \
        "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx" \
        -O "$COMFYUI_DIR/models/onnx/vitpose_h_wholebody_model.onnx"
    echo "[OK] vitpose"
fi

echo "[OK] Все модели скачаны"

# ============================================================
# ШАГ 5: Workflow
# ============================================================
echo "[6/7] Скачиваем workflow..."
mkdir -p "$COMFYUI_DIR/user/default/workflows"
wget -q "$GITHUB_RAW/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json" && \
    echo "[OK] Workflow сохранён" || echo "[WARN] Workflow не скачан"

# ============================================================
# ШАГ 6: Перезапуск ComfyUI
# ============================================================
echo "[7/7] Перезапускаем ComfyUI..."
supervisorctl restart comfyui 2>/dev/null || true
sleep 3
rm -f /.provisioning

echo ""
echo "=============================================="
echo " ✅ ANIMATOR V2 готов! [$(date)]"
echo " Лог: $LOG_FILE"
echo "=============================================="