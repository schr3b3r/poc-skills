---
name: fulcra-otter-vitals
description: Cross-reference and align an Otter.ai meeting transcript (.txt) with a user's heart rate time series during that meeting. Uses an Otter.ai style text transcript and the JSON output from `fulcra-calendar-vitals`.
---

# Fulcra Otter Vitals

This skill maps physical meeting transcripts exported from Otter.ai directly to the exact second-by-second heart rate time series of the user. It allows the user to see exactly what was being said in a meeting at the exact moment their heart rate spiked or dropped.

## Prerequisites

1. The user must upload their `.txt` meeting transcript to the Fulcra file system at `/meeting-transcripts/otter/<timestamp>/`. (The script will automatically detect the most recent upload in this folder).
2. The user must have already generated a `combined_data.json` file using the `fulcra-calendar-vitals` skill, which contains their calendar events merged with their high-resolution heart rate data.

## Usage

Use the bundled `scripts/fetch_and_align.sh` script to process the data and generate the output. 

You must pass two arguments to the script:
1. The path to the `combined_data.json` file.
2. The exact title of the meeting as it appears in the calendar data.

```bash
./scripts/fetch_and_align.sh path/to/combined_data.json "My Weekly Sync"
```

Under the hood, this script connects to the Fulcra API, retrieves the most recent transcript from the `/meeting-transcripts/otter` folder, and aligns it with the local calendar and heart rate data using `align_transcript.js`.

## Output

The script will render an ASCII chart (if `asciichart` is installed via npm) of the heart rate during the meeting. 
Most importantly, it will output the top 5 highest heart rate spikes during that meeting, and annotate them with the exact quote that was actively being spoken in the meeting during that exact second.

If the user asks for a visualization or correlation of a transcript, wrap the exact terminal output of this script in a markdown code block (````text````) and provide it to them directly in the chat.
