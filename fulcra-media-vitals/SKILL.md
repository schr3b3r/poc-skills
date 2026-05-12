---
name: fulcra-media-vitals
description: Analyze a local media file (video or photo), extract its exact recording timestamp and duration using EXIF data, and query the Fulcra CLI to plot the user's biometrics (like HeartRate) during the exact moment the media was captured.
---

# Fulcra Media Vitals

This skill maps physiological data to arbitrary media files. By extracting the embedded `CreationDate` and `Duration` from a photo or video file, this skill automatically queries Fulcra for the matching biometric data and renders a chart of the user's physical state during the recording.

## Prerequisites

1. The user must be authenticated with the Fulcra CLI.
2. The user must provide the file path to a media file (e.g., `.mov`, `.mp4`, `.jpg`).
3. The host system must have `exiftool` installed to extract the media metadata.
   - If missing, the agent should run: `sudo apt-get update && sudo apt-get install -y exiftool`

## Usage

If the user wants to analyze a file that exists on the Fulcra API (via the undocumented file upload endpoints), you **must** temporarily download the file to the workspace first, run the analysis, and then optionally delete the downloaded file to save space.

Use the bundled `scripts/extract_and_plot.js` script to process the local file and generate the output. 

You must pass the path to the media file as the first argument. You can optionally pass a Fulcra metric ID (like `HeartRate` or `StepCount`) as the second argument.

```bash
# Analyze a video and plot HeartRate (default)
node scripts/extract_and_plot.js /path/to/video.MOV

# Analyze a photo and plot StepCount
node scripts/extract_and_plot.js /path/to/photo.jpg StepCount
```

## Output & Visualization

If the user asks for a visualization or analysis of a media file, wrap the exact terminal output of this script in a markdown code block (````text````) and provide it to them directly in the chat.

**Important Data Quirk:** Apple Watches (and similar wearables) only sample heart rate every 5-10 minutes unless the user is actively tracking a Workout. If the script reports that "No HeartRate data was recorded", inform the user that their device was likely in background-sampling mode during that specific 1-2 minute video window.
