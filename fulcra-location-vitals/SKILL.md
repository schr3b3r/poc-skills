---
name: fulcra-location-vitals
description: Correlate Fulcra location timeseries data with other vitals, like average heart rate. This skill figures out when the user changed locations (using distance granularity filtering) and overlays the average heart rate during each stay. Use this to help build JSON pipelines for the fulcra-skills dashboard.
---

# Fulcra Location Vitals

This skill maps the user's location history over a period of time to their physiological data (such as average heart rate). It uses the Fulcra CLI's `location-time-series` command with explicit granularity to detect physical movement between different locations and groups physiological metrics within those stay periods.

## Prerequisites

This skill requires the Fulcra CLI to be authenticated via `auth login`. 

## Usage

Use the bundled script `scripts/align.sh` to fetch and align the data. The script accepts a relative or absolute time range.

```bash
# Fetch the last 1 day of location stays and average heart rate
./scripts/align.sh "1 day" > combined_location_hr.json

# Fetch the last 1 week
./scripts/align.sh "1 week" > combined_location_hr.json
```

## How It Works

1. It executes `location-time-series` using `-s 900` (15-minute sample rate check) and `-m 100` (only registers a new sample if the user has moved at least 100 meters).
2. It reverse-geocodes each coordinate using `-r` to capture the `address`.
3. It iterates through each location segment, and uses `get-records HeartRate` to fetch all raw heart rate data during the time the user was at that location.
4. It computes the mathematical average of the heart rate and appends it to the location object as `average_heart_rate`.
5. It returns a combined JSON array suitable for import into the `fulcra-skills-dash` Svelte web app.

## Notes for the Agent
- If the user asks for a visual summary in chat, you can parse this JSON output and display a simple Markdown table summarizing where they were and their average heart rate.
- For generating UI dashboard data, execute `align.sh "1 day" > static/data/location_vitals.json` inside the scaffolded Svelte app.