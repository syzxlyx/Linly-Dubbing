#!/usr/bin/env bash
set -euo pipefail

# Setup helper for Linly-Talker submodule
# - Creates an isolated env (conda preferred, else venv)
# - Prints next-step commands to run

SUBMODULE_DIR="$(cd "$(dirname "$0")/../../submodules/Linly-Talker" && pwd)"
ENV_NAME="linly_talker"
PY_VER="3.10"

echo "[Linly-Talker] Submodule path: $SUBMODULE_DIR"

if command -v conda >/dev/null 2>&1; then
  echo "[Linly-Talker] Using conda to create env: $ENV_NAME (python=$PY_VER)"
  conda create -n "$ENV_NAME" python="$PY_VER" -y
  echo "[Linly-Talker] Activate with: conda activate $ENV_NAME"
else
  echo "[Linly-Talker] Conda not found; falling back to python venv"
  python3 -m venv "$SUBMODULE_DIR/.venv"
  echo "[Linly-Talker] Activate with: source $SUBMODULE_DIR/.venv/bin/activate"
fi

echo "[Linly-Talker] Next steps (manual):"
echo "  1) cd $SUBMODULE_DIR"
echo "  2) Follow upstream README to install requirements and download models"
echo "  3) Start WebUI or run CLI as upstream recommends"

