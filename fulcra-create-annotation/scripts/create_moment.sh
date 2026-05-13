#!/bin/bash
# scripts/create_moment.sh

NAME="$1"
DESC="$2"

if [ -z "$NAME" ] || [ -z "$DESC" ]; then
    echo "Usage: ./create_moment.sh \"Annotation Name\" \"Annotation Description\""
    exit 1
fi

echo "Fetching Fulcra access token..."
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# The Fulcra API responds with a 303 See Other, and puts the location of the new resource in the headers.
echo "Creating Moment Annotation: $NAME..."
RESPONSE=$(curl -s -i -X POST "https://api.fulcradynamics.com/user/v1alpha1/annotation" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$NAME\",
    \"description\": \"$DESC\",
    \"annotation_type\": \"moment\",
    \"tags\": []
  }")

# Extract the location header
LOCATION=$(echo "$RESPONSE" | grep -i "location:" | awk '{print $2}' | tr -d '\r')

if [ -n "$LOCATION" ]; then
    ANNOTATION_ID=$(basename "$LOCATION")
    echo "----------------------------------------"
    echo "Successfully created Moment Annotation!"
    echo "Name: $NAME"
    echo "ID: $ANNOTATION_ID"
    echo "----------------------------------------"
    echo "Save this ID! It is the unique identifier for querying logs against this annotation later."
else
    echo "Failed to create annotation. Response:"
    echo "$RESPONSE"
    exit 1
fi
