#!/bin/bash
# fetch_and_align.sh <combined_data.json> "Meeting Title"

COMBINED_JSON="$1"
MEETING_TITLE="$2"

if [ -z "$COMBINED_JSON" ] || [ -z "$MEETING_TITLE" ]; then
    echo "Usage: ./fetch_and_align.sh <path_to_combined_data.json> \"Meeting Title\""
    exit 1
fi

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# 1. List folders in /meeting-transcripts/otter
FOLDERS_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload?path=/meeting-transcripts/otter")
LATEST_FOLDER=$(echo "$FOLDERS_JSON" | jq -r '.folders[]?' | sort -r | head -n 1)

if [ -z "$LATEST_FOLDER" ]; then
    echo "Error: No folders found in /meeting-transcripts/otter"
    exit 1
fi

echo "Found latest transcript folder: $LATEST_FOLDER"

# 2. List files in that folder
FILES_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload?path=/meeting-transcripts/otter/$LATEST_FOLDER")

# We assume there is a .txt file we want
FILE_ID=$(echo "$FILES_JSON" | jq -r '.files[] | select(.name | endswith(".txt")) | .id' | head -n 1)
FILE_NAME=$(echo "$FILES_JSON" | jq -r '.files[] | select(.name | endswith(".txt")) | .name' | head -n 1)

if [ -z "$FILE_ID" ]; then
    echo "Error: No .txt file found in /meeting-transcripts/otter/$LATEST_FOLDER"
    exit 1
fi

echo "Downloading transcript: $FILE_NAME ($FILE_ID)..."

TMP_DIR=$(mktemp -d)
TRANSCRIPT_PATH="$TMP_DIR/$FILE_NAME"

curl -s -L -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload/$FILE_ID/download" -o "$TRANSCRIPT_PATH"

echo "Download complete! Running alignment..."
echo "----------------------------------------"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$DIR/align_transcript.js" "$TRANSCRIPT_PATH" "$COMBINED_JSON" "$MEETING_TITLE"

# Cleanup
rm -rf "$TMP_DIR"
