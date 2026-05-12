---
name: fulcra-annotation-vitals
description: Automatically discover a user's active, custom Duration Annotations (e.g. tracking "Guitar Practice" or "Reading") via the Fulcra CLI and correlate those recorded sessions with their heart rate time series.
---

# Fulcra Annotation Vitals

This skill maps a user's biometric data directly against the manual activity sessions they track using Fulcra "Duration Annotations". It dynamically discovers all active custom annotation types and pulls heart rate data for every recorded instance.

## Prerequisites

This skill relies heavily on the `fulcra` skill. Before using this skill, ensure the user is authenticated with the Fulcra CLI. If you receive authentication errors, refer to the `fulcra` skill documentation to log the user in.

## Usage

Use the bundled script `scripts/align.sh` to fetch and align the data. 

Under the hood, this script:
1. Calls `catalog` and filters for IDs starting with `DurationAnnotation/`.
2. Explicitly filters for `.categories` including `"user_configured"`.
3. Explicitly filters out soft-deleted schemas (`.metadata.deleted_at != null`).
4. Iterates over the surviving IDs and uses `get-records` to pull the actual session history.
5. Overlays 1-second `HeartRate` metrics on top of each session's `.recorded_at.start_time` and `.recorded_at.end_time`.

It outputs a combined JSON array of all annotation sessions, each containing a `heart_rate_series` property.

```bash
# Execute the alignment script for a specific time range (defaults to "1 week")
./scripts/align.sh "1 week" > combined_annotations.json
```

## ASCII Visualizations

If the user asks to see a chart, graph, or visual representation of their duration annotations:

1. Generate the JSON data using the `align.sh` script.
2. Run the `plot_vitals.js` script, passing in the JSON data file. (Note: `npm install asciichart` is required).
   ```bash
   node scripts/plot_vitals.js combined_annotations.json
   ```
3. Wrap the exact output of the script inside a Markdown code block (` ```text `) and include it in your final chat response to the user so they can see the chart directly.

## Note on Fulcra IDs

When using the Fulcra CLI `get-records` command for annotations, you **must** use the full ID string as returned by the catalog (e.g., `DurationAnnotation/e4d4d3a3-b5ef-48a1-bee7-5ea6425399ee`). Do not split the string or pass only the UUID. The `align.sh` script handles this correctly automatically.
