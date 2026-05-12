#!/bin/bash
# scripts/align.sh

TIME_RANGE=${1:-"1 day"}
INCLUDE_ALL_DAY=${2:-"false"}

echo "Fetching calendar events for range: $TIME_RANGE (Include All-Day: $INCLUDE_ALL_DAY)" >&2

EVENTS_JSONL=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' calendar-events "$TIME_RANGE")

echo "["
FIRST=true
TMP_DIR=$(mktemp -d)

while read -r EVENT; do
    [ -z "$EVENT" ] && continue

    IS_ALL_DAY=$(echo "$EVENT" | jq -r '.is_all_day')
    DELETED_AT=$(echo "$EVENT" | jq -r '.deleted_at // empty')
    
    # Skip deleted events
    if [ -n "$DELETED_AT" ] && [ "$DELETED_AT" != "null" ]; then
        continue
    fi

    # Skip all-day events unless explicitly requested
    if [ "$IS_ALL_DAY" == "true" ] && [ "$INCLUDE_ALL_DAY" != "true" ]; then
        continue
    fi

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ","
    fi

    START=$(echo "$EVENT" | jq -r '.start_date')
    END=$(echo "$EVENT" | jq -r '.end_date')

    SAMPLE_RATE=1
    if [ "$IS_ALL_DAY" == "true" ]; then
        SAMPLE_RATE=1800
    fi

    uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' metric-time-series \
      --sample-rate "$SAMPLE_RATE" \
      --agg-function mean \
      HeartRate "$START" "$END" > "$TMP_DIR/hr.jsonl" 2>/dev/null

    jq -s '.' "$TMP_DIR/hr.jsonl" > "$TMP_DIR/hr_array.json"
    echo "$EVENT" | jq --slurpfile hr "$TMP_DIR/hr_array.json" '. + {heart_rate_series: $hr[0]}'

done <<< "$EVENTS_JSONL"

echo "]"
rm -rf "$TMP_DIR"
