# 📋 Инструкция — Создание шаблона на vast.ai

## 1. Зайди на vast.ai → Templates → New Template

## 2. Заполни поля:

**Docker Image:**
```
vastai/comfyui
```

**On-start script** (вставь целиком):
```bash
#!/bin/bash
LOG_FILE="/workspace/animator_setup.log"
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
GITHUB_ZIP_URL="https://github.com/YOUR_USERNAME/animator-v2/releases/latest/download/custom_nodes.zip"
GITHUB_RAW="https://raw.githubusercontent.com/YOUR_USERNAME/animator-v2/main"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "ANIMATOR V2 Auto Setup [$(date)]"

for i in $(seq 1 30); do
    [ -d "$COMFYUI_DIR" ] && break || sleep 5
done

TMP_ZIP="/tmp/custom_nodes.zip"
TMP_EXTRACT="/tmp/custom_nodes_extracted"
wget -q --show-progress "$GITHUB_ZIP_URL" -O "$TMP_ZIP"
rm -rf "$TMP_EXTRACT" && mkdir -p "$TMP_EXTRACT"
unzip -q "$TMP_ZIP" -d "$TMP_EXTRACT"
mkdir -p "$CUSTOM_NODES_DIR"
INNER=$(ls "$TMP_EXTRACT") && COUNT=$(echo "$INNER" | wc -l)
if [ "$COUNT" -eq 1 ] && [ -d "$TMP_EXTRACT/$INNER" ]; then
    cp -r "$TMP_EXTRACT/$INNER"/. "$CUSTOM_NODES_DIR/"
else
    cp -r "$TMP_EXTRACT"/. "$CUSTOM_NODES_DIR/"
fi
rm -rf "$TMP_ZIP" "$TMP_EXTRACT"

pip install -q -r "$COMFYUI_DIR/requirements.txt"
for d in "$CUSTOM_NODES_DIR"/*/; do
    [ -f "$d/requirements.txt" ] && pip install -q -r "$d/requirements.txt"
done

mkdir -p "$COMFYUI_DIR/user/default/workflows"
wget -q "$GITHUB_RAW/workflow/animator_v2_workflow.json" \
    -O "$COMFYUI_DIR/user/default/workflows/animator_v2_workflow.json"

supervisorctl restart comfyui
echo "DONE [$(date)]"
```

**Disk Space:** `50 GB` минимум

**Exposed ports:** `8188` (ComfyUI UI)

## 3. Сохрани шаблон → используй при аренде GPU

## 4. После старта инстанса

- Дождись 3–5 минут пока всё установится
- Открой ComfyUI по адресу `http://IP:8188`
- Воркфлоу уже будет в папке workflows
- Загрузи модели в `/workspace/ComfyUI/models/`

## 5. Проверить лог установки:
```bash
cat /workspace/animator_setup.log
```
