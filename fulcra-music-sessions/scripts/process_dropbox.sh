#!/bin/bash
# scripts/process_dropbox.sh

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# 1. List files in /music-writing-sessions/_dropbox
FILES_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload?path=/music-writing-sessions/_dropbox")

# We want to process audio files (.mp3, .wav, .m4a, etc). Ignoring .keep
AUDIO_FILES=$(echo "$FILES_JSON" | jq -c '.files[] | select(.name != ".keep")')

if [ -z "$AUDIO_FILES" ]; then
    echo "No audio files found in dropbox."
    exit 0
fi

TMP_DIR=$(mktemp -d)
echo "Processing files in temporary directory: $TMP_DIR"

echo "$AUDIO_FILES" | while read -r file_obj; do
    FILE_ID=$(echo "$file_obj" | jq -r '.id')
    FILE_NAME=$(echo "$file_obj" | jq -r '.name')
    FILE_CREATED=$(echo "$file_obj" | jq -r '.created_at') # E.g., "2026-05-13T14:04:29.38437Z"
    
    echo "Downloading $FILE_NAME ($FILE_ID)..."
    DOWNLOAD_PATH="$TMP_DIR/$FILE_NAME"
    curl -s -L -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload/$FILE_ID/download" -o "$DOWNLOAD_PATH"
    
    # Extract just the file name and extension
    BASENAME=$(basename -- "$FILE_NAME")
    EXTENSION="${BASENAME##*.}"
    FILENAME_NO_EXT="${BASENAME%.*}"
    
    # Extract actual embedded creation date using exiftool if available
    EMBEDDED_DATE=$(exiftool -s -s -s -d "%Y%m%dT%H%M%SZ" -CreateDate "$DOWNLOAD_PATH" 2>/dev/null)
    
    if [ -n "$EMBEDDED_DATE" ]; then
        TIMESTAMP_FOLDER="$EMBEDDED_DATE"
        echo "Found embedded creation date: $TIMESTAMP_FOLDER"
    else
        # Fallback to upload timestamp
        TIMESTAMP_FOLDER=$(date -d "$FILE_CREATED" -u +"%Y%m%dT%H%M%SZ" 2>/dev/null)
        if [ -z "$TIMESTAMP_FOLDER" ]; then
            TIMESTAMP_FOLDER=$(echo "$FILE_CREATED" | sed -e 's/[-:]//g' -e 's/\..*Z/Z/')
        fi
        echo "No embedded date found, using upload date: $TIMESTAMP_FOLDER"
    fi

    # Clean the filename spaces and weird chars
    CLEAN_FILENAME=$(echo "$FILENAME_NO_EXT" | sed -e 's/[^A-Za-z0-9_-]/_/g')".$EXTENSION"
    
    # Rename the local file so upload_memory.sh picks up the clean basename
    mv "$DOWNLOAD_PATH" "$TMP_DIR/$CLEAN_FILENAME"
    DOWNLOAD_PATH="$TMP_DIR/$CLEAN_FILENAME"
    
    # Determine media type based on extension
    MEDIA_TYPE="audio"
    case "${EXTENSION,,}" in
        mp4|mov|avi|mkv|webm|m4v)
            MEDIA_TYPE="video"
            ;;
        mp3|wav|m4a|flac|aac|ogg)
            MEDIA_TYPE="audio"
            ;;
        *)
            echo "Warning: Unrecognized extension .$EXTENSION. Defaulting to audio."
            MEDIA_TYPE="audio"
            ;;
    esac
    
    DEST_PATH="/music-writing-sessions/$MEDIA_TYPE/$TIMESTAMP_FOLDER"
    
    echo "Uploading $CLEAN_FILENAME to $DEST_PATH..."
    ~/.openclaw/workspace/poc-skills/fulcra-agent-memory-sync/scripts/upload_memory.sh "$DOWNLOAD_PATH" "$DEST_PATH"
    
    # If successful, delete the original from the dropbox
    if [ $? -eq 0 ]; then
        echo "Upload successful! Deleting original from dropbox..."
        curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload/$FILE_ID"
    else
        echo "Failed to upload $CLEAN_FILENAME to $DEST_PATH. Leaving in dropbox."
    fi
    echo "------------------------------------------------"
done

rm -rf "$TMP_DIR"
echo "Dropbox processing complete."
