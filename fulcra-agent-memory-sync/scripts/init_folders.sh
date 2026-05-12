#!/bin/bash
ROOT_FOLDER=${1:-"/agent-memory"}

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

echo "Checking if $ROOT_FOLDER exists..."
# We can implicitly "create" folders in S3/GCS by simply uploading an empty placeholder file (like a .keep file) into them.
# The API doesn't have an explicit POST /mkdir endpoint, so placing a 0-byte file forces the folder to exist.

# Create an empty placeholder file locally
touch .keep

# 1. Initialize root folder (optional, but good practice)
echo "Initializing $ROOT_FOLDER..."
curl -s -o /dev/null -X POST "https://api.fulcradynamics.com/input/v1/file_upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{ \"content_length\": 0, \"content_type\": \"text/plain\", \"name\": \".keep\", \"path\": \"$ROOT_FOLDER\" }" \
  | jq -r '.url' | xargs -I {} curl -s -o /dev/null -X PUT "{}" -H "Content-Length: 0" --data-binary "@.keep"

# 2. Initialize backups subfolder
echo "Initializing $ROOT_FOLDER/backups..."
curl -s -o /dev/null -X POST "https://api.fulcradynamics.com/input/v1/file_upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{ \"content_length\": 0, \"content_type\": \"text/plain\", \"name\": \".keep\", \"path\": \"$ROOT_FOLDER/backups\" }" \
  | jq -r '.url' | xargs -I {} curl -s -o /dev/null -X PUT "{}" -H "Content-Length: 0" --data-binary "@.keep"

# 3. Initialize latest subfolder
echo "Initializing $ROOT_FOLDER/latest..."
curl -s -o /dev/null -X POST "https://api.fulcradynamics.com/input/v1/file_upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{ \"content_length\": 0, \"content_type\": \"text/plain\", \"name\": \".keep\", \"path\": \"$ROOT_FOLDER/latest\" }" \
  | jq -r '.url' | xargs -I {} curl -s -o /dev/null -X PUT "{}" -H "Content-Length: 0" --data-binary "@.keep"

# Cleanup
rm .keep

echo "Initialization complete! Run a 'curl' query against $ROOT_FOLDER to verify."
