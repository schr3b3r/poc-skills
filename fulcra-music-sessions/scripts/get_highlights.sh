#!/bin/bash
# scripts/get_highlights.sh

AUDIO_FILE="$1"
ANNOTATION_ID="MomentAnnotation/ee4178d5-1109-4ad7-addf-0967bb715d20"

if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: ./get_highlights.sh /path/to/audio/file.m4a"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "File not found: $AUDIO_FILE"
    exit 1
fi

echo "Extracting metadata for $AUDIO_FILE..."

START_UTC_RAW=$(exiftool -s -s -s -d "%Y-%m-%dT%H:%M:%SZ" -CreateDate "$AUDIO_FILE" 2>/dev/null)

if [ -z "$START_UTC_RAW" ]; then
    echo "Could not find embedded CreateDate in $AUDIO_FILE. Cannot reliably extract highlights."
    exit 1
fi

DURATION_MS=$(mediainfo --Inform="Audio;%Duration%" "$AUDIO_FILE" 2>/dev/null | head -n 1)

if [ -z "$DURATION_MS" ]; then
    echo "Could not extract duration."
    exit 1
fi

DURATION_SEC=$(awk "BEGIN {print $DURATION_MS / 1000}")
END_UTC_RAW=$(date -d "$START_UTC_RAW + $DURATION_SEC seconds" -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Session Start: $START_UTC_RAW"
echo "Session End:   $END_UTC_RAW"
echo "----------------------------------------"
echo "Querying Fulcra for 'Jam Session Highlight' annotations in this window..."

HIGHLIGHTS=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' get-records "$ANNOTATION_ID" "$START_UTC_RAW" "$END_UTC_RAW")

if [ -z "$HIGHLIGHTS" ] || [ "$HIGHLIGHTS" == "[]" ] || echo "$HIGHLIGHTS" | grep -q "Error"; then
    echo "No highlights found during this session."
else
    echo "Highlights Found:"
    # Use python to safely parse the JSON array and calculate the exact second offsets
    python3 -c "
import sys, json
from datetime import datetime, timezone

raw_json = sys.stdin.read().strip()
if not raw_json:
    sys.exit(0)

highlights = json.loads(raw_json)

# If the API returned a single object instead of an array, wrap it
if isinstance(highlights, dict):
    highlights = [highlights]

start_time_str = '$START_UTC_RAW'
start_dt = datetime.strptime(start_time_str, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)

for h in highlights:
    record_time_str = h.get('recorded_at')
    if not record_time_str: continue
    try:
        if record_time_str.endswith('Z'):
            record_dt = datetime.strptime(record_time_str, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
        else:
            record_dt = datetime.fromisoformat(record_time_str)
            
        offset_seconds = int((record_dt - start_dt).total_seconds())
        
        # Calculate human readable mm:ss
        m, s = divmod(offset_seconds, 60)
        time_format = f\"{m:02d}:{s:02d}\"
        
        print(f\" - Marker at: [{time_format}] ({offset_seconds}s into the track)\")
    except Exception as e:
        print(f\" - Marker at: {record_time_str} | Offset Error: {e}\")
    " <<< "$HIGHLIGHTS"
fi
