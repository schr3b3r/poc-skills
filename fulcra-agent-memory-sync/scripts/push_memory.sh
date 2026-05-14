#!/bin/bash
# scripts/push_memory.sh
# Creates a tarball of the local agent memory (MEMORY.md and memory/ directory) and uploads it to Fulcra.

WORKSPACE="/home/leif/.openclaw/workspace"
ARCHIVE_PATH="/tmp/memory_archive.tar.gz"
BASE_DIR="$(dirname "$0")"

cd "$WORKSPACE" || exit 1

# Check if either MEMORY.md or memory/ exists
if [ ! -f "MEMORY.md" ] && [ ! -d "memory" ]; then
    echo "No memory files found in $WORKSPACE to backup."
    exit 1
fi

echo "Creating memory archive..."
# Create a tarball containing MEMORY.md and the memory directory
# Using a glob to avoid errors if one doesn't exist, but we ensure at least one exists above
FILES_TO_TAR=""
[ -f "MEMORY.md" ] && FILES_TO_TAR="MEMORY.md"
[ -d "memory" ] && FILES_TO_TAR="$FILES_TO_TAR memory/"

tar -czf "$ARCHIVE_PATH" $FILES_TO_TAR

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

echo "1. Uploading timestamped backup..."
"$BASE_DIR/upload_memory.sh" "$ARCHIVE_PATH" "/agent-memory/backups/$TIMESTAMP"

echo "2. Updating latest state..."
"$BASE_DIR/upload_memory.sh" "$ARCHIVE_PATH" "/agent-memory/latest"

echo "Push complete! Archive uploaded to Fulcra."
rm -f "$ARCHIVE_PATH"
