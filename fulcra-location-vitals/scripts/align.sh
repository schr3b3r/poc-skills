#!/bin/bash
# scripts/align.sh

TIME_RANGE=${1:-"1 day"}

echo "Fetching location timeseries for range: $TIME_RANGE" >&2

# We use -s 900 (15 min) and -m 100 (100 meters) to only get location slices when the user has moved at least 100 meters
LOCATIONS_JSON=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' location-time-series "$TIME_RANGE" -s 900 -m 100 -r | jq -s '
  . as $arr |
  [
    range(0; length) |
    {
      start_time: $arr[.].slice_time,
      end_time: (if $arr[.+1] then $arr[.+1].slice_time else null end),
      address: $arr[.].address,
      lat: $arr[.].lat,
      lng: $arr[.].long
    }
  ]
')

# Get current time in ISO8601 for the last entry's end_time
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "["
FIRST=true
TMP_DIR=$(mktemp -d)

# Iterate through each location entry
echo "$LOCATIONS_JSON" | jq -c '.[]' | while read -r LOC; do
    [ -z "$LOC" ] && continue

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ","
    fi

    START=$(echo "$LOC" | jq -r '.start_time')
    END=$(echo "$LOC" | jq -r '.end_time')

    if [ "$END" == "null" ]; then
        END=$NOW
    fi

    # Fetch all heart rate records during this location stay and calculate the mean
    # We use get-records to grab raw values and jq to average them
    uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' get-records HeartRate "$START" "$END" 2>/dev/null > "$TMP_DIR/hr_raw.jsonl"
    
    AVG_HR=$(cat "$TMP_DIR/hr_raw.jsonl" | jq -s '[.[] | .value] | if length > 0 then add/length else null end')

    # Add the average heart rate to the location JSON object
    echo "$LOC" | jq --argjson hr "$AVG_HR" '. + {average_heart_rate: $hr, end_time: "'"$END"'"}'

done

echo "]"
rm -rf "$TMP_DIR"