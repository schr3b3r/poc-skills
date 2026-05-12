#!/bin/bash
# scripts/align.sh

TIME_RANGE=${1:-"1 day"}
echo "Fetching calendar events for range: $TIME_RANGE" >&2

EVENTS_JSONL=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' calendar-events "$TIME_RANGE")

echo "["
FIRST=true
TMP_DIR=$(mktemp -d)

while read -r EVENT; do
    [ -z "$EVENT" ] && continue

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ","
    fi

    START=$(echo "$EVENT" | jq -r '.start_date')
    END=$(echo "$EVENT" | jq -r '.end_date')
    IS_ALL_DAY=$(echo "$EVENT" | jq -r '.is_all_day')

    # Default sample rate is 1s, but 30 minutes (1800s) for all-day events
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
