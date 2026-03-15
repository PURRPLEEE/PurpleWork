# 🎬 ANIMATOR V2 — WanVideo Pose-Driven Animation

Готовый ComfyUI воркфлоу для генерации анимации с переносом позы, лица и движений через WanVideo + Uni3C ControlNet.

---

## 📦 Что внутри

| Файл | Описание |
|------|----------|
| `workflow/animator_v2_workflow.json` | Основной воркфлоу ComfyUI |
| `install.sh` | Ручная установка custom nodes |
| `on_start.sh` | Авто-установка для vast.ai |
| `custom_nodes.zip` | Архив с custom nodes (в Releases) |

---

## 🚀 Запуск на vast.ai (автоматически)

### Шаг 1 — Создай шаблон на vast.ai

| Поле | Значение |
|------|----------|
| **Docker Image** | `vastai/comfyui` |
| **On-start script** | Вставь содержимое `on_start.sh` |
| **Disk** | минимум **50 GB** |
| **GPU** | RTX 3090 / 4090 / A100 |

### Шаг 2 — Дождись запуска

Скрипт автоматически:
1. Скачивает `custom_nodes.zip` с GitHub Releases
2. Распаковывает все папки в `/workspace/ComfyUI/custom_nodes/`
3. Запускает `pip install` для всех зависимостей
4. Скачивает воркфлоу в папку ComfyUI
5. Перезапускает ComfyUI

Лог установки: `/workspace/animator_setup.log`

### Шаг 3 — Загрузи модели

Нужные модели положи в соответствующие папки:

```
/workspace/ComfyUI/models/
├── diffusion_models/
│   ├── WanModel.safetensors
│   └── Wan21_Uni3C_controlnet_fp16.safetensors
├── vae/
│   └── vae.safetensors
├── clip/
│   ├── text_enc.safetensors
│   └── klip_vision.safetensors
└── loras/
    ├── light.safetensors
    ├── wan.reworked.safetensors
    ├── WanPusa.safetensors
    └── WanFun.reworked.safetensors
```

---

## 🛠️ Ручная установка (Jupyter / локально)

```bash
# 1. Скачай custom_nodes.zip из Releases и распакуй в custom_nodes
unzip custom_nodes.zip -d /workspace/ComfyUI/custom_nodes/

# 2. Установи зависимости
pip install -r /workspace/ComfyUI/requirements.txt

cd /workspace
for d in ComfyUI/custom_nodes/*; do
  if [ -f "$d/requirements.txt" ]; then
    pip install -r "$d/requirements.txt"
  fi
done

# 3. Перезапусти ComfyUI
supervisorctl restart comfyui
```

---

## 🎯 Воркфлоу — что делает

- **Вход**: референс-изображение персонажа + видео с движением
- **Обработка**: детекция позы (ViTPose) → WanVideo Sampler + Uni3C ControlNet
- **Выход**: видео с перенесённым движением на персонажа

### Основные параметры

| Параметр | Значение | Описание |
|----------|----------|----------|
| `steps` | 4 | Количество шагов диффузии |
| `denoise_strength` | 0.75 | Сила деноиза |
| `pose_strength` | 0.7 | Сила переноса позы |
| `face_strength` | 0.6 | Сила переноса лица |
| `resolution` | 720×1280 | Разрешение выхода |
| `fps` | 30 | Частота кадров |

---

## ⚠️ Важно

- Перед первым запуском жди **2–3 минуты** после распаковки custom nodes
- Если ComfyUI не видит ноды — перезагрузи страницу браузера
- Проверь лог установки: `cat /workspace/animator_setup.log`

---

## 📋 Используемые Custom Nodes

- `ComfyUI-WanVideoWrapper` — основной враппер WanVideo
- `ComfyUI-VideoHelperSuite (VHS)` — загрузка/сохранение видео
- `ComfyUI-KJNodes` — утилиты (ресайз и др.)
- `ComfyUI-ViTPose` — детекция позы и лица (ONNX)
- `ComfyUI-TravelSuite (TS)` — цветокоррекция, превью, комбайн
