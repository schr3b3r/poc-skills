---
name: fulcra-music-sessions
description: Processes raw music writing session audio files uploaded to a dropbox folder, cleans up their filenames, and safely moves them to timestamped archive folders in Fulcra.
---

# Fulcra Music Sessions

This skill handles the automated organization of music writing session audio. It is designed to act as a background job that watches a specific "_dropbox" folder in the user's Fulcra cloud storage, downloads any audio files it finds, and re-uploads them into neatly organized, timestamped archive folders.

This is the first step in a workflow that allows a user to drop a continuous `MomentAnnotation` whenever they play something they like during a jam session, and later use a web UI to snap back to those exact highlight moments in the audio.

## Prerequisites

1. The user must export or upload their raw audio sessions (e.g., `.wav`, `.mp3`, `.m4a`) directly into the Fulcra file system at `/music-writing-sessions/_dropbox/`.
2. The user must be authenticated with the Fulcra CLI.

## Usage

Use the bundled `scripts/process_dropbox.sh` script to parse the dropbox and archive the files.

```bash
./scripts/process_dropbox.sh
```

Under the hood, this script connects to the Fulcra API, retrieves all files from the `/music-writing-sessions/_dropbox` folder, generates a clean timestamped destination folder based on the file's creation/upload time, uploads the file to the new location, and deletes the original from the _dropbox.
