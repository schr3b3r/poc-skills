---
name: fulcra-meeting-vitals
description: Cross-reference and align a meeting transcript (.txt) with a user's heart rate time series during that meeting. Uses an Otter.ai style text transcript and the JSON output from `fulcra-calendar-vitals`.
---

# Fulcra Meeting Vitals

This skill maps physical meeting transcripts (like those exported from Zoom or Otter.ai) directly to the exact second-by-second heart rate time series of the user. It allows the user to see exactly what was being said in a meeting at the exact moment their heart rate spiked or dropped.

## Prerequisites

1. The user must provide a meeting transcript in `.txt` format (which contains timestamped utterances like `John Doe 12:34`).
2. The user must have already generated a `combined_data.json` file using the `fulcra-calendar-vitals` skill, which contains their calendar events merged with their high-resolution heart rate data.

## Usage

Use the bundled `scripts/align_transcript.js` script to process the data and generate the output. 

You must pass three arguments to the script:
1. The path to the transcript `.txt` file.
2. The path to the `combined_data.json` file.
3. The exact title of the meeting as it appears in the calendar data.

```bash
node scripts/align_transcript.js path/to/transcript.txt path/to/combined_data.json "My Weekly Sync"
```

## Output

The script will render an ASCII chart (if `asciichart` is installed via npm) of the heart rate during the meeting. 
Most importantly, it will output the top 5 highest heart rate spikes during that meeting, and annotate them with the exact quote that was actively being spoken in the meeting during that exact second.

If the user asks for a visualization or correlation of a transcript, wrap the exact terminal output of this script in a markdown code block (````text````) and provide it to them directly in the chat.
