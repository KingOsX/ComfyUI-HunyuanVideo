#!/bin/bash

# ============================================================================
#  ComfyUI + HunyuanVideo 1.5 - RunPod One-Click Installer
#  Usage: bash install.sh [--720p] [--fp16] [--full] [--i2v] [--sr] [--4step] [--light]
#
#  DISK SPACE REQUIRED:
#    Default (fp8 480p) : ~35 GB  -> Set Volume Disk to  50 GB on RunPod
#    --720p             : ~45 GB  -> Set Volume Disk to  75 GB on RunPod
#    --full (everything): ~100 GB -> Set Volume Disk to 150 GB on RunPod
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="/workspace/install.log"

log()  { echo -e "${CYAN}[INSTALL]${NC} $1" | tee -a "$LOG_FILE"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $1" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[ERROR ]${NC} $1" | tee -a "$LOG_FILE"; }

# --- Default config ---
WORKSPACE="/workspace"
RESOLUTION="480p"
PRECISION="fp8"
DOWNLOAD_I2V=false
DOWNLOAD_SR=false
DOWNLOAD_4STEP_LORA=false
FULL_MODE=false
LIGHT_MODE=false
LISTEN_PORT=8188

# --- Init log file ---
echo "" >> "$LOG_FILE"
echo "========== $(date) ==========" >> "$LOG_FILE"

# --- Parse arguments ---
for arg in "$@"; do
  case $arg in
    --720p)
      RESOLUTION="720p"
      shift ;;
    --fp16)
      PRECISION="fp16"
      shift ;;
    --full)
      FULL_MODE=true
      RESOLUTION="720p"
      PRECISION="fp16"
      DOWNLOAD_I2V=true
      DOWNLOAD_SR=true
      DOWNLOAD_4STEP_LORA=true
      shift ;;
    --i2v)
      DOWNLOAD_I2V=true
      shift ;;
    --sr)
      DOWNLOAD_SR=true
      shift ;;
    --4step)
      DOWNLOAD_4STEP_LORA=true
      shift ;;
    --light)
      LIGHT_MODE=true
      shift ;;
    *)
      warn "Unknown argument: $arg" ;;
  esac
done

# --- Determine model filenames based on config ---
HF_BASE="https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files"

# T2V diffusion model
if [ "$RESOLUTION" = "720p" ]; then
  # 720p T2V is only available in fp16
  DIFFUSION_MODEL="hunyuanvideo1.5_720p_t2v_fp16.safetensors"
else
  if [ "$PRECISION" = "fp16" ]; then
    DIFFUSION_MODEL="hunyuanvideo1.5_480p_t2v_cfg_distilled_fp16.safetensors"
  else
    DIFFUSION_MODEL="hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors"
  fi
fi

# Text encoders
if [ "$PRECISION" = "fp16" ]; then
  TEXT_ENCODER_QWEN="qwen_2.5_vl_7b.safetensors"
else
  TEXT_ENCODER_QWEN="qwen_2.5_vl_7b_fp8_scaled.safetensors"
fi
TEXT_ENCODER_BYT5="byt5_small_glyphxl_fp16.safetensors"

# VAE
VAE_MODEL="hunyuanvideo15_vae_fp16.safetensors"

# I2V diffusion model (if requested)
if [ "$DOWNLOAD_I2V" = true ]; then
  if [ "$RESOLUTION" = "720p" ]; then
    if [ "$PRECISION" = "fp16" ]; then
      I2V_MODEL="hunyuanvideo1.5_720p_i2v_cfg_distilled_fp16.safetensors"
    else
      I2V_MODEL="hunyuanvideo1.5_720p_i2v_cfg_distilled_fp8_scaled.safetensors"
    fi
  else
    if [ "$PRECISION" = "fp16" ]; then
      I2V_MODEL="hunyuanvideo1.5_480p_i2v_cfg_distilled_fp16.safetensors"
    else
      I2V_MODEL="hunyuanvideo1.5_480p_i2v_cfg_distilled_fp8_scaled.safetensors"
    fi
  fi
  CLIP_VISION="sigclip_vision_patch14_384.safetensors"
fi

# SR models (if requested)
if [ "$DOWNLOAD_SR" = true ]; then
  if [ "$PRECISION" = "fp16" ]; then
    SR_720P="hunyuanvideo1.5_720p_sr_distilled_fp16.safetensors"
    SR_1080P="hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors"
  else
    SR_720P="hunyuanvideo1.5_720p_sr_distilled_fp8_scaled.safetensors"
    SR_1080P="hunyuanvideo1.5_1080p_sr_distilled_fp8_scaled.safetensors"
  fi
fi

# 4-step LoRA
LORA_4STEP="hunyuanvideo1.5_t2v_480p_lightx2v_4step_lora_rank_32_bf16.safetensors"

COMFY_DIR="$WORKSPACE/ComfyUI"

echo ""
echo "=============================================="
echo "  ComfyUI + HunyuanVideo 1.5 Installer"
echo "  for RunPod"
echo "=============================================="
echo ""
log "Resolution        : $RESOLUTION"
log "Precision         : $PRECISION"
log "T2V Model         : $DIFFUSION_MODEL"
log "Text Encoder (1)  : $TEXT_ENCODER_QWEN"
log "Text Encoder (2)  : $TEXT_ENCODER_BYT5"
log "VAE               : $VAE_MODEL"
log "Image-to-Video    : $DOWNLOAD_I2V"
log "Super-Resolution  : $DOWNLOAD_SR"
log "4-Step LoRA       : $DOWNLOAD_4STEP_LORA"
log "Workspace         : $WORKSPACE"
echo ""

# --- Check available disk space ---
AVAILABLE_GB=$(df -BG "$WORKSPACE" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -lt 40 ]; then
  warn "Only ${AVAILABLE_GB} GB disk space available!"
  warn "Recommended: 50 GB minimum (Volume Disk on RunPod)"
  warn "Continuing anyway..."
  echo ""
fi

# ============================================================================
# 1. System dependencies
# ============================================================================
log "Installing system dependencies..."
if apt-get update -qq && apt-get install -y -qq git wget ffmpeg libgl1 > /dev/null 2>&1; then
  ok "System dependencies installed"
else
  warn "apt-get failed (may already be installed, continuing...)"
fi

# ============================================================================
# 2. Clone ComfyUI
# ============================================================================
if [ -d "$COMFY_DIR" ]; then
  log "ComfyUI already exists, pulling latest..."
  cd "$COMFY_DIR" && git pull --quiet || warn "git pull failed (offline?), using existing version"
else
  log "Cloning ComfyUI..."
  git clone --quiet https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" || {
    err "Failed to clone ComfyUI - check network"
  }
fi
cd "$COMFY_DIR"
ok "ComfyUI ready"

# ============================================================================
# 3. Install Python dependencies
# ============================================================================
log "Upgrading pip..."
python -m pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE" || true

log "Installing ComfyUI Python dependencies..."
pip install -r requirements.txt 2>&1 | tee -a "$LOG_FILE" || warn "Some pip dependencies failed"

log "Installing extra dependencies..."
pip install sqlalchemy alembic aiohttp aiosqlite 2>&1 | tee -a "$LOG_FILE" || warn "Some extra dependencies failed"

# Verify critical modules are installed
CRITICAL_MODULES="torch sqlalchemy alembic aiohttp tqdm yaml PIL numpy"
for mod in $CRITICAL_MODULES; do
  python -c "import $mod" 2>/dev/null || {
    warn "Module '$mod' missing, attempting install..."
    pip install "$mod" 2>&1 | tee -a "$LOG_FILE" || true
  }
done
ok "ComfyUI dependencies installed"

# ============================================================================
# 4. Install custom nodes
# ============================================================================
log "Installing custom nodes..."
cd "$COMFY_DIR/custom_nodes"

install_node() {
  local name="$1"
  local url="$2"
  if [ -d "$name" ]; then
    log "  Updating $name..."
    (cd "$name" && git pull --quiet) || warn "  Failed to update $name"
  else
    log "  Cloning $name..."
    git clone "$url" "$name" 2>&1 | tee -a "$LOG_FILE"
    if [ ! -d "$name" ]; then
      err "  FAILED to clone $name - retrying..."
      git clone "$url" "$name" 2>&1 | tee -a "$LOG_FILE" || err "  $name clone failed after retry"
    fi
  fi
  if [ -f "$name/requirements.txt" ]; then
    pip install -r "$name/requirements.txt" 2>&1 | tee -a "$LOG_FILE" || warn "  Some deps for $name failed"
  fi
}

# ComfyUI-Manager (essential - install first)
install_node "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager.git"

# VideoHelperSuite (for video output)
install_node "ComfyUI-VideoHelperSuite" "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# KJNodes (utility nodes)
if [ "$LIGHT_MODE" != true ]; then
  install_node "ComfyUI-KJNodes" "https://github.com/kijai/ComfyUI-KJNodes.git"
fi

# Verify ComfyUI-Manager is installed
if [ -d "ComfyUI-Manager" ]; then
  ok "Custom nodes installed (ComfyUI-Manager verified)"
else
  err "ComfyUI-Manager is MISSING! Install manually:"
  err "  cd $COMFY_DIR/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git"
fi

# ============================================================================
# 5. Create model directories
# ============================================================================
cd "$COMFY_DIR"
mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/clip_vision
mkdir -p models/loras

# ============================================================================
# 6. Download models
# ============================================================================
download() {
  local url="$1"
  local dest="$2"
  local filename=$(basename "$dest")
  # Skip if already downloaded and not empty
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    ok "Already downloaded: $filename"
    return
  fi
  # Remove empty/broken files
  [ -f "$dest" ] && rm -f "$dest"
  log "Downloading $filename (this may take a while)..."
  wget -q --show-progress -O "$dest" "$url" || {
    warn "Failed to download $filename - removing broken file"
    rm -f "$dest"
    return 1
  }
  ok "Downloaded: $filename"
}

# --- T2V Diffusion model ---
download "$HF_BASE/diffusion_models/$DIFFUSION_MODEL" \
  "models/diffusion_models/$DIFFUSION_MODEL"

# --- Text encoder: Qwen 2.5 VL 7B ---
download "$HF_BASE/text_encoders/$TEXT_ENCODER_QWEN" \
  "models/text_encoders/$TEXT_ENCODER_QWEN"

# --- Text encoder: ByT5 Small GlyphXL ---
download "$HF_BASE/text_encoders/$TEXT_ENCODER_BYT5" \
  "models/text_encoders/$TEXT_ENCODER_BYT5"

# --- VAE ---
download "$HF_BASE/vae/$VAE_MODEL" \
  "models/vae/$VAE_MODEL"

# --- I2V model + CLIP Vision ---
if [ "$DOWNLOAD_I2V" = true ]; then
  download "$HF_BASE/diffusion_models/$I2V_MODEL" \
    "models/diffusion_models/$I2V_MODEL"

  download "$HF_BASE/clip_vision/$CLIP_VISION" \
    "models/clip_vision/$CLIP_VISION"
fi

# --- Super-Resolution models ---
if [ "$DOWNLOAD_SR" = true ]; then
  download "$HF_BASE/diffusion_models/$SR_720P" \
    "models/diffusion_models/$SR_720P"

  download "$HF_BASE/diffusion_models/$SR_1080P" \
    "models/diffusion_models/$SR_1080P"
fi

# --- 4-Step LoRA ---
if [ "$DOWNLOAD_4STEP_LORA" = true ]; then
  download "$HF_BASE/loras/$LORA_4STEP" \
    "models/loras/$LORA_4STEP"
fi

# ============================================================================
# 7. Fix known dependency issues
# ============================================================================
log "Fixing potential dependency conflicts..."
pip install -q --force-reinstall protobuf sentencepiece 2>&1 | tee -a "$LOG_FILE" || true
ok "Dependencies fixed"

# ============================================================================
# 8. Verify downloads
# ============================================================================
log "Verifying downloads..."
MISSING=0
for f in \
  "models/diffusion_models/$DIFFUSION_MODEL" \
  "models/text_encoders/$TEXT_ENCODER_QWEN" \
  "models/text_encoders/$TEXT_ENCODER_BYT5" \
  "models/vae/$VAE_MODEL" \
; do
  if [ ! -s "$f" ]; then
    warn "MISSING or EMPTY: $f"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -gt 0 ]; then
  warn "$MISSING required model(s) missing! Check disk space (df -h) and re-run."
else
  ok "All required models verified"
fi

# ============================================================================
# 9. Summary
# ============================================================================
echo ""
echo "=============================================="
echo -e "${GREEN}  Installation complete!${NC}"
echo "=============================================="
echo ""
echo "  Config: HunyuanVideo 1.5 | ${RESOLUTION} | ${PRECISION}"
echo ""
echo "  Models downloaded:"
echo "    - T2V Model        : $DIFFUSION_MODEL"
echo "    - Text Encoder (1) : $TEXT_ENCODER_QWEN"
echo "    - Text Encoder (2) : $TEXT_ENCODER_BYT5"
echo "    - VAE              : $VAE_MODEL"
[ "$DOWNLOAD_I2V" = true ] && \
echo "    - I2V Model        : $I2V_MODEL" && \
echo "    - CLIP Vision      : $CLIP_VISION"
[ "$DOWNLOAD_SR" = true ] && \
echo "    - SR 720p          : $SR_720P" && \
echo "    - SR 1080p         : $SR_1080P"
[ "$DOWNLOAD_4STEP_LORA" = true ] && \
echo "    - 4-Step LoRA      : $LORA_4STEP"
echo ""
USED=$(du -sh "$COMFY_DIR/models" 2>/dev/null | awk '{print $1}')
echo "  Total models size: $USED"
echo ""
echo "  HunyuanVideo 1.5 uses native ComfyUI nodes:"
echo "    - UNETLoader         -> loads diffusion model"
echo "    - DualCLIPLoader     -> loads Qwen 2.5 VL + ByT5"
echo "    - VAELoader          -> loads VAE"
echo ""
echo "  To start ComfyUI:"
echo "    cd $COMFY_DIR && python main.py --listen 0.0.0.0 --port $LISTEN_PORT"
echo ""
echo "=============================================="

# ============================================================================
# 10. Auto-start ComfyUI (with auto-restart on crash)
# ============================================================================
log "Starting ComfyUI on port $LISTEN_PORT..."
cd "$COMFY_DIR"

MAX_RETRIES=5
RETRY_COUNT=0
while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  log "Launching ComfyUI (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
  python main.py --listen 0.0.0.0 --port "$LISTEN_PORT" 2>&1 | tee -a "$LOG_FILE"
  EXIT_CODE=$?
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ "$EXIT_CODE" -eq 0 ]; then
    break
  fi
  warn "ComfyUI exited with code $EXIT_CODE, restarting in 5s..."
  sleep 5
done

if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
  err "ComfyUI failed after $MAX_RETRIES attempts. Check $LOG_FILE for details."
fi

# Keep container alive even if ComfyUI fails
log "ComfyUI stopped. Keeping container alive for debugging..."
log "Check logs: cat $LOG_FILE"
log "Restart manually: cd $COMFY_DIR && python main.py --listen 0.0.0.0 --port $LISTEN_PORT"
sleep infinity
