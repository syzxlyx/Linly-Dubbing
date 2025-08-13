#!/usr/bin/env bash
set -euo pipefail

# Setup helper for UVR5 submodule (ultimatevocalremovergui)
# - Creates an isolated env (conda preferred, else venv)
# - Prints next-step commands to launch the tool
# NOTE: We do not pin dependencies here: follow upstream README for platform-specific notes.

SUBMODULE_DIR="$(cd "$(dirname "$0")/../../submodules/UVR5" && pwd)"
ENV_NAME="uvr5"
PY_VER="3.11"

echo "[UVR5] Submodule path: $SUBMODULE_DIR"

if command -v conda >/dev/null 2>&1; then
  echo "[UVR5] Using conda to create env: $ENV_NAME (python=$PY_VER)"
  conda create -n "$ENV_NAME" python="$PY_VER" -y
  echo "[UVR5] Activate with: conda activate $ENV_NAME"
  echo "[UVR5] Then install dependencies following upstream README inside: $SUBMODULE_DIR"
else
  echo "[UVR5] Conda not found; falling back to python venv"
  python3 -m venv "$SUBMODULE_DIR/.venv"
  echo "[UVR5] Activate with: source $SUBMODULE_DIR/.venv/bin/activate"
fi

echo "[UVR5] Next steps (manual):"
echo "  1) cd $SUBMODULE_DIR"
echo "  2) Follow upstream README to install requirements and models"
echo "  3) Run the UI or CLI as documented upstream"

