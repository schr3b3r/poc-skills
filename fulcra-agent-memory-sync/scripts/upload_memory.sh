#!/bin/bash
# scripts/upload_memory.sh

# Defaults to the agent's MEMORY.md if no argument is provided
FILE_PATH=${1:-"/home/leif/.openclaw/workspace/MEMORY.md"}
UPLOAD_PATH=${2:-"/agent-memory"}
FILE_NAME=$(basename "$FILE_PATH")

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at $FILE_PATH"
    exit 1
fi

# Detect content type (default to text/markdown for MEMORY.md, or generic binary)
if [[ "$FILE_NAME" == *.md ]]; then
    CONTENT_TYPE="text/markdown"
elif [[ "$FILE_NAME" == *.json ]]; then
    CONTENT_TYPE="application/json"
else
    CONTENT_TYPE=$(file -b --mime-type "$FILE_PATH")
fi

CONTENT_LENGTH=$(stat -c%s "$FILE_PATH")

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

if [ -z "$TOKEN" ]; then
    echo "Error: Could not retrieve access token. Are you authenticated?"
    exit 1
fi

echo "Requesting pre-signed upload URL for $UPLOAD_PATH/$FILE_NAME..."
# 1. Get the upload URL
RESPONSE=$(curl -s -X POST "https://api.fulcradynamics.com/input/v1/file_upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"content_length\": $CONTENT_LENGTH,
    \"content_type\": \"$CONTENT_TYPE\",
    \"name\": \"$FILE_NAME\",
    \"path\": \"$UPLOAD_PATH\"
  }")

# Extract the URL
UPLOAD_URL=$(echo "$RESPONSE" | jq -r '.url // .upload_url // empty')

if [ -z "$UPLOAD_URL" ]; then
    echo "Failed to get upload URL. API Response:"
    echo "$RESPONSE" | jq .
    exit 1
fi

echo "Successfully retrieved upload URL. Uploading file data..."

# 2. Upload the file
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$UPLOAD_URL" \
  -H "Content-Type: $CONTENT_TYPE" \
  -H "Content-Length: $CONTENT_LENGTH" \
  --data-binary "@$FILE_PATH")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Upload complete! $FILE_NAME is now securely stored in Fulcra at $UPLOAD_PATH."
else
    echo "Upload failed with HTTP status: $HTTP_STATUS"
    exit 1
fi
