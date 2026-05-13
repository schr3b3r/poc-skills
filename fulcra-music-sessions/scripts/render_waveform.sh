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
# We'll pass the raw UTC start string to format the labels at the bottom
start_utc_str = sys.argv[4] if len(sys.argv) > 4 else ""

import datetime
try:
    start_dt = datetime.datetime.strptime(start_utc_str, "%Y-%m-%dT%H:%M:%SZ")
except:
    start_dt = None

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

if start_dt:
    end_dt = start_dt + datetime.timedelta(seconds=duration_sec)
    marker_dt = start_dt + datetime.timedelta(seconds=annotation_offset)
    
    start_lbl = start_dt.strftime("%H:%M:%S")
    end_lbl = end_dt.strftime("%H:%M:%S")
    marker_lbl = marker_dt.strftime("%H:%M:%S")
    
    # We want to place the marker label exactly where the marker arrow is
    timeline = " " * margin
    
    # If the marker is close to the start or end, it might overlap. Let's just do a simple absolute positioned string.
    # W is 75. 
    # Left bound = start_lbl
    # Right bound = end_lbl right aligned to W
    # Marker bound = marker_lbl at marker_index
    
    # Build a character array to easily place strings
    line_chars = [" "] * (W + len(end_lbl) + 10)
    
    def place_str(idx, text):
        for i, c in enumerate(text):
            if idx + i < len(line_chars):
                line_chars[idx + i] = c
                
    place_str(0, start_lbl)
    place_str(marker_index, marker_lbl)
    place_str(W - len(end_lbl), end_lbl)
    
    print(" " * margin + "".join(line_chars).rstrip())
    
PYEOF

# Extract the Start Time from the audio file so we can pass it to the python script
START_UTC_RAW=$(exiftool -s -s -s -d "%Y-%m-%dT%H:%M:%SZ" -CreateDate "$AUDIO_FILE" 2>/dev/null)

echo ""
echo "--- Audio Waveform for $(basename "$AUDIO_FILE") ---"
"$VENV_DIR/bin/python" /tmp/render_waveform.py "$WAV_TMP" "$ANNOTATION_OFFSET" "$ANNOTATION_NAME" "$START_UTC_RAW"
echo "---------------------------------------------------------------------------------"

rm -f "$WAV_TMP"
rm -f /tmp/render_waveform.py
