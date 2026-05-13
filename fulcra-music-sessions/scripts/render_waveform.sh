#!/bin/bash
# scripts/render_waveform.sh

AUDIO_FILE="$1"
ANNOTATION_OFFSET="$2"
ANNOTATION_NAME="${3:-Jam Session Highlight}"

if [ -z "$AUDIO_FILE" ] || [ -z "$ANNOTATION_OFFSET" ]; then
    echo "Usage: ./render_waveform.sh /path/to/audio/file.m4a <annotation_offset_in_seconds> [\"Annotation Name\"]"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "File not found: $AUDIO_FILE"
    exit 1
fi

# Ensure uv virtual environment exists for our dependencies
VENV_DIR="/tmp/waveform_venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Setting up temporary Python environment for waveform rendering..."
    uv venv "$VENV_DIR" >/dev/null 2>&1
    uv pip install --python "$VENV_DIR/bin/python" imageio-ffmpeg asciichartpy >/dev/null 2>&1
fi

FFMPEG_BIN=$("$VENV_DIR/bin/python" -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")

if [ -z "$FFMPEG_BIN" ]; then
    echo "Error: Could not find ffmpeg binary."
    exit 1
fi

WAV_TMP=$(mktemp --suffix=".wav")

# Convert to 16-bit mono 8000Hz WAV
"$FFMPEG_BIN" -y -v quiet -i "$AUDIO_FILE" -ac 1 -ar 8000 -acodec pcm_s16le "$WAV_TMP"

cat << 'PYEOF' > /tmp/render_waveform.py
import sys, wave, struct
import asciichartpy

audio_path = sys.argv[1]
annotation_offset = float(sys.argv[2])
annotation_name = sys.argv[3]

try:
    with wave.open(audio_path, 'rb') as wf:
        nframes = wf.getnframes()
        raw_frames = wf.readframes(nframes)
        framerate = wf.getframerate()
        duration_sec = nframes / float(framerate)
        
        # Unpack 16-bit signed little-endian
        num_samples = len(raw_frames) // 2
        samples = struct.unpack(f"<{num_samples}h", raw_frames)
        
        W = 75
        samples_per_bucket = num_samples // W
        
        amplitudes = []
        neg_amplitudes = []
        for i in range(W):
            start = i * samples_per_bucket
            end = start + samples_per_bucket
            bucket = samples[start:end]
            
            # Use RMS
            if len(bucket) > 0:
                sq_sum = sum((s)**2 for s in bucket)
                amp = (sq_sum / len(bucket)) ** 0.5
            else:
                amp = 0
            amplitudes.append(amp)
            neg_amplitudes.append(-amp)
            
except Exception as e:
    print("Error:", e)
    sys.exit(1)

config = {
    'height': 12,
    'format': '{:8.0f}'
}
print(asciichartpy.plot([amplitudes, neg_amplitudes], config))

marker_index = int((annotation_offset / duration_sec) * W)
if marker_index >= W:
    marker_index = W - 1

margin = 11
marker_line = " " * margin + " " * marker_index + f"▲ {annotation_name} ({int(annotation_offset)}s)"
print(marker_line)
PYEOF

echo ""
echo "--- Audio Waveform for $(basename "$AUDIO_FILE") ---"
"$VENV_DIR/bin/python" /tmp/render_waveform.py "$WAV_TMP" "$ANNOTATION_OFFSET" "$ANNOTATION_NAME"
echo "---------------------------------------------------------------------------------"

rm -f "$WAV_TMP"
rm -f /tmp/render_waveform.py
