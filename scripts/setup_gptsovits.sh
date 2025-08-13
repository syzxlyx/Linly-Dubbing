#!/usr/bin/env bash
set -euo pipefail

# Setup helper for GPT-SoVITS submodule
# - Creates an isolated env (conda preferred, else venv)
# - Prints next-step commands to run inference

SUBMODULE_DIR="$(cd "$(dirname "$0")/../../submodules/GPT-SoVITS" && pwd)"
ENV_NAME="gptsovits"
PY_VER="3.10"

echo "[GPT-SoVITS] Submodule path: $SUBMODULE_DIR"

if command -v conda >/dev/null 2>&1; then
  echo "[GPT-SoVITS] Using conda to create env: $ENV_NAME (python=$PY_VER)"
  conda create -n "$ENV_NAME" python="$PY_VER" -y
  echo "[GPT-SoVITS] Activate with: conda activate $ENV_NAME"
else
  echo "[GPT-SoVITS] Conda not found; falling back to python venv"
  python3 -m venv "$SUBMODULE_DIR/.venv"
  echo "[GPT-SoVITS] Activate with: source $SUBMODULE_DIR/.venv/bin/activate"
fi

echo "[GPT-SoVITS] Next steps (manual):"
echo "  1) cd $SUBMODULE_DIR"
echo "  2) Follow upstream README to install requirements and download models"
echo "  3) Start WebUI or run CLI inference as upstream recommends"

