---
name: fulcra-create-annotation
description: Creates new annotations directly in the user's Fulcra account via the API. Captures the unique Annotation ID returned so it can be saved in memory for future analytical queries.
---

# Fulcra Create Annotation

This skill allows the agent to dynamically create new `MomentAnnotation` configurations in the user's Fulcra account.

When building workflows that combine external data (like audio or transcripts) with user-logged events, the agent needs to know the precise underlying ID of the annotation being used. 

By having the agent create the annotation itself via this skill, it can capture the resulting `ID` from the API and save it securely to its `MEMORY.md`. 

## Prerequisites

1. The user must be authenticated with the Fulcra CLI.

## Usage

Use the bundled `scripts/create_moment.sh` script to create a Moment Annotation.

```bash
./scripts/create_moment.sh "Jam Session Highlight" "Tracks specific highlights during music writing."
```

## Post-Creation Step

The script will output the new Annotation's unique ID. **You must immediately record this ID** (usually in your `MEMORY.md`) alongside its purpose so you can use it in future API queries or data analysis pipelines. 
