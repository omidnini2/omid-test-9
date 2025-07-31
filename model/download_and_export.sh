#!/usr/bin/env bash
# دانلود مدل فارسی Coqui-TTS و تبدیل به ONNX کوانتیزه (FP16)
set -e

PYTHON=$(command -v python3 || command -v python)

if [ -z "$PYTHON" ]; then
  echo "Python not found. Install Python 3.8+ first." >&2
  exit 1
fi

# 1) محیط مجازی توصیه می‌شود ولی اجباری نیست
pip install --upgrade --quiet TTS onnxruntime onnxruntime-tools

# 2) دانلود مدل فارسی VITS اگر وجود ندارد
MODEL_DIR="fa_vits_model"
CHECKPOINT="$MODEL_DIR/model.pth"
CONFIG="$MODEL_DIR/config.json"
SPEAKER_ENC="$MODEL_DIR/speaker_encoder.pth"

if [ ! -f "$CHECKPOINT" ]; then
  echo "Downloading Persian VITS model..."
  tts --model_name tts_models/fa/vits --download_path $MODEL_DIR
fi

# 3) تبدیل به ONNX
python export_to_onnx.py --checkpoint $CHECKPOINT --config $CONFIG --output model.onnx --speaker_encoder $SPEAKER_ENC

# 4) کوانتیزه FP16
onnxruntime_tools.optimizer_cli --input model.onnx --output model.opt.onnx --float16 --opt_level basic

# 5) کپی به mobile_app/assets
mkdir -p ../mobile_app/assets
cp model.opt.onnx ../mobile_app/assets/model.opt.onnx

echo "✅ ONNX مدل فارسی آماده شد: mobile_app/assets/model.opt.onnx"