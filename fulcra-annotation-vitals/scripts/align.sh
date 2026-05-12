#!/bin/bash
# scripts/align.sh

TIME_RANGE=${1:-"1 week"}
echo "Fetching active duration annotations..." >&2

# 1. Fetch catalog and filter for user-configured DurationAnnotations that are NOT soft-deleted
CATALOG_JSONL=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' catalog)

# We use jq to parse the JSONL catalog and extract just the IDs we care about
ACTIVE_ANNOTATION_IDS=$(echo "$CATALOG_JSONL" | jq -r '
    select(.id | startswith("DurationAnnotation")) 
    | select(.categories | index("user_configured") != null) 
    | select(.metadata.deleted_at == null) 
    | .id
')

if [ -z "$ACTIVE_ANNOTATION_IDS" ]; then
    echo "No active user-configured Duration Annotations found." >&2
    echo "[]"
    exit 0
fi

echo "["
FIRST=true
TMP_DIR=$(mktemp -d)

# 2. Iterate over each active annotation type
for ANNOTATION_ID in $ACTIVE_ANNOTATION_IDS; do
    echo "Fetching records for: $ANNOTATION_ID in range: $TIME_RANGE" >&2
    
    # Notice: We must pass the FULL ID ("DurationAnnotation/uuid") to get-records, not just the UUID suffix.
    RECORDS_JSONL=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' get-records "$ANNOTATION_ID" "$TIME_RANGE" 2>/dev/null)
    
    # 3. Process each recorded session
    while read -r RECORD; do
        [ -z "$RECORD" ] && continue
        
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi

        # The structure for annotations puts dates in recorded_at
        START=$(echo "$RECORD" | jq -r '.recorded_at.start_time')
        END=$(echo "$RECORD" | jq -r '.recorded_at.end_time')

        # Annotations are assumed to be specific sessions, so we use high-res 1s sample rate
        uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' metric-time-series \
          --sample-rate 1 \
          --agg-function mean \
          HeartRate "$START" "$END" > "$TMP_DIR/hr.jsonl" 2>/dev/null

        jq -s '.' "$TMP_DIR/hr.jsonl" > "$TMP_DIR/hr_array.json"
        
        # Inject the heart rate series directly into the record object
        echo "$RECORD" | jq --slurpfile hr "$TMP_DIR/hr_array.json" '. + {heart_rate_series: $hr[0]}'

    done <<< "$RECORDS_JSONL"
done

echo "]"
rm -rf "$TMP_DIR"
