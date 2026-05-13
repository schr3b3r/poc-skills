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
    # We can just output the raw JSON for now, or use Python to safely parse and calculate offsets
    echo "$HIGHLIGHTS" | jq .
fi
