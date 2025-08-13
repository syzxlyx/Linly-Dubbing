#!/usr/bin/env bash
set -euo pipefail
# Minimal wrapper: synthesize speech with GPT-SoVITS per-sentence and merge
# Usage: bash scripts/submodules/gptsovits_synthesize.sh videos/<project>/<video> <text_file>
# - <text_file>: a plain text with one sentence per line (align with your translation.json if needed)

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <video_folder> <text_file>"
  exit 1
fi

VID_DIR="$1"
TEXT_FILE="$2"
SUB_DIR="$(cd "$(dirname "$0")/../../submodules/GPT-SoVITS" && pwd)"
OUT_DIR="$VID_DIR/gptsovits_out"
mkdir -p "$OUT_DIR"

# NOTE: GPT-SoVITS upstream provides various entrypoints (WebUI/CLI).
# Here we only scaffold the workflow and leave the actual TTS call to the user, since interfaces differ.

LINE_NO=0
while IFS= read -r line; do
  ((LINE_NO++))
  SENT_TXT="$line"
  OUT_WAV="$OUT_DIR/sent_$(printf "%04d" "$LINE_NO").wav"
  echo "[GPT-SoVITS] TODO synth: '$SENT_TXT' -> $OUT_WAV"
  # Example (pseudo): python infer_cli.py --text "$SENT_TXT" --spk sample.wav --out "$OUT_WAV"
done < "$TEXT_FILE"

echo "[GPT-SoVITS] All sentence WAVs should be placed in $OUT_DIR. Merge with ffmpeg:"
echo "  ffmpeg -y -f concat -safe 0 -i <(for f in $OUT_DIR/*.wav; do echo \"file '$PWD/$f'\"; done) -c copy '$VID_DIR/gptsovits_full.wav'"
echo "Then mix with instrumental:"
echo "  ffmpeg -y -i '$VID_DIR/gptsovits_full.wav' -i '$VID_DIR/audio_instruments.wav' -filter_complex amix=inputs=2:normalize=0 '$VID_DIR/audio_combined.wav'"

