#!/bin/bash
# scripts/pull_memory.sh
# Downloads the latest memory_archive.tar.gz from Fulcra and extracts it.

WORKSPACE="/home/leif/.openclaw/workspace"
ARCHIVE_PATH="/tmp/memory_archive.tar.gz"

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# List the files in /agent-memory/latest
echo "Checking /agent-memory/latest for memory_archive.tar.gz..."
FILE_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload?path=/agent-memory/latest" | jq -r '.files[] | select(.name == "memory_archive.tar.gz")')

if [ -z "$FILE_JSON" ]; then
    echo "Error: No memory_archive.tar.gz found in /agent-memory/latest."
    exit 1
fi

INPUT_ID=$(echo "$FILE_JSON" | jq -r '.id')
echo "Found archive with ID: $INPUT_ID"

echo "Downloading archive..."
curl -s -L -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload/$INPUT_ID/download" -o "$ARCHIVE_PATH"

echo "Extracting archive into $WORKSPACE..."
cd "$WORKSPACE" || exit 1
tar -xzf "$ARCHIVE_PATH"

echo "Success! Agent memory restored."
rm -f "$ARCHIVE_PATH"
