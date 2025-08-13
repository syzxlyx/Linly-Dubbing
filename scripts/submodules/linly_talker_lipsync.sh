#!/usr/bin/env bash
set -euo pipefail
# Minimal wrapper: drive lip-sync with Linly-Talker
# Usage: bash scripts/submodules/linly_talker_lipsync.sh <image_or_video> <audio> <out_video>

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <image_or_video> <audio> <out_video>"
  exit 1
fi

SRC_VIS="$1"
SRC_AUD="$2"
OUT_MP4="$3"
SUB_DIR="$(cd "$(dirname "$0")/../../submodules/Linly-Talker" && pwd)"

# Upstream entrypoint varies; provide guidance
echo "[Linly-Talker] Please run the appropriate inference command inside: $SUB_DIR"
echo "Example (pseudo): python infer.py --source '$SRC_VIS' --audio '$SRC_AUD' --out '$OUT_MP4' --fps 30 --size 720p"
echo "If the project provides WebUI, export from UI and move file to: $OUT_MP4"

