#!/bin/bash
FILE_PATH=${1:-"/home/leif/.openclaw/workspace/MEMORY.md"}
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at $FILE_PATH"
    exit 1
fi

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
BASE_DIR="$(dirname "$0")"

echo "1. Creating timestamped backup..."
"$BASE_DIR/upload_memory.sh" "$FILE_PATH" "/agent-memory/backups/$TIMESTAMP"

echo "2. Updating latest state pointer..."
"$BASE_DIR/upload_memory.sh" "$FILE_PATH" "/agent-memory/latest"

echo "Sync complete!"
