#!/usr/bin/env bash
set -euo pipefail
# Minimal wrapper: run UVR5 (ultimatevocalremovergui) separation for a given video folder
# Usage: bash scripts/submodules/uvr5_separate.sh videos/<project>/<video>

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <video_folder>"
  exit 1
fi

VID_DIR="$1"
AUDIO_IN="$VID_DIR/audio.wav"
VOCALS_OUT="$VID_DIR/audio_vocals.wav"
INST_OUT="$VID_DIR/audio_instruments.wav"
SUB_DIR="$(cd "$(dirname "$0")/../../submodules/UVR5" && pwd)"

if [[ ! -f "$AUDIO_IN" ]]; then
  echo "[UVR5] Missing $AUDIO_IN. Extract it first: ffmpeg -y -i download.mp4 -vn -ac 2 -ar 44100 audio.wav"
  exit 1
fi

# Placeholder: upstream UVR5-UI provides GUI; many forks expose CLI via python-audio-separator.
# Here we guide the user. Replace with actual CLI if available in your UVR5 checkout.
echo "[UVR5] Please run separation inside: $SUB_DIR, then copy results back as:"
echo "  vocals -> $VOCALS_OUT"
echo "  instrumental -> $INST_OUT"
echo "Tip: Some UVR5 forks support CLI via python-audio-separator, e.g.:"
echo "  audio-separator --model mdx --input '$AUDIO_IN' --output '$VID_DIR'"
echo "  && mv <vocals.wav> '$VOCALS_OUT' && mv <instrumental.wav> '$INST_OUT'"

