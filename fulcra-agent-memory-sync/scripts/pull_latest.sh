#!/bin/bash
DEST_PATH=${1:-"/home/leif/.openclaw/workspace/MEMORY.md"}

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# List the files in /agent-memory/latest
echo "Checking /agent-memory/latest for MEMORY.md..."
FILE_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload?path=/agent-memory/latest" | jq -r '.files[] | select(.name == "MEMORY.md")')

if [ -z "$FILE_JSON" ]; then
    echo "Error: No MEMORY.md found in /agent-memory/latest."
    exit 1
fi

INPUT_ID=$(echo "$FILE_JSON" | jq -r '.id')
echo "Found file with ID: $INPUT_ID"

echo "Downloading..."
curl -s -L -H "Authorization: Bearer $TOKEN" "https://api.fulcradynamics.com/input/v1/file_upload/$INPUT_ID/download" -o "$DEST_PATH"

echo "Success! Downloaded latest memory to $DEST_PATH"
