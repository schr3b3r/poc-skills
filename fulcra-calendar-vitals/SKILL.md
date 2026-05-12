---
name: fulcra-calendar-vitals
description: Correlate Fulcra calendar events with high-resolution heart rate time series data. Trigger this skill whenever a user asks something like "Hey, show me my heart rate based on my meetings today using Fulcra" or wants to visualize their vitals against their schedule. Helps generate combined JSON data for dashboard creation.
---

# Fulcra Calendar Vitals

This skill correlates Apple Calendar events with Fulcra HeartRate metric time series data. It uses the Fulcra CLI to fetch calendar events and overlays 1-second granular heart rate data for each event's time window.

## Prerequisites

This skill relies heavily on the `fulcra` skill. Before using this skill, ensure the user is authenticated with the Fulcra CLI. If you receive authentication errors, refer to the `fulcra` skill documentation to log the user in via `auth login`.

## Usage

Use the bundled script `scripts/align.sh` to fetch and align the data. It outputs a combined JSON array of calendar events, each containing a `heart_rate_series` property. It intelligently adjusts the sample rate (1s for standard events, 30min for all-day events) to prevent overloading the system.

```bash
# Execute the alignment script for a specific time range (defaults to "1 day")
./scripts/align.sh "1 day" > combined_data.json
```

## ASCII Visualizations

If the user specifically uses the marketing prompt ("Hey, show me my heart rate based on my meetings today using Fulcra"), or explicitly asks for a visual representation or ASCII chart, you **MUST** provide the exact terminal output directly in the chat using the visualization script.

1. Generate the JSON data using the `align.sh` script.
2. Run the `plot_vitals.js` script, passing in the JSON data file. (Note: `npm install asciichart` is required).
   ```bash
   node scripts/plot_vitals.js combined_data.json
   ```
3. Wrap the exact output of the script inside a Markdown code block (` ```text `) and include it in your final chat response to the user so they can see the chart directly.

## Notes for the Agent

- The Fulcra CLI (`calendar-events` and `metric-time-series`) outputs JSONL (JSON Lines). 
- `metric-time-series` uses positional arguments for the time range (e.g., `HeartRate "2026-05-06T17:30:00Z" "2026-05-06T18:30:00Z"`).
- The `scripts/align.sh` handles parsing the JSONL, extracting `start_date` and `end_date`, fetching the metric time series, and merging the data with `jq`.
- Provide the output `combined_data.json` to any web dashboard or data visualization tool the user is building.