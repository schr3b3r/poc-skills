---
name: fulcra-agent-memory-sync
description: Temporary skill to upload the agent's MEMORY.md file (or any other state files) directly to the Fulcra cloud file storage. Uses the undocumented file upload endpoints to securely sync agent context to the user's Fulcra account.
---

# Fulcra Agent Memory Sync (Temporary)

This is a temporary workaround skill designed to back up agent memory and contextual files directly to Fulcra's cloud file storage endpoints. This allows agents to persist their state (like `MEMORY.md`) to a safe remote location and decouple it from local machine lifecycles.

*Note: The Fulcra CLI will eventually support file operations natively. Until then, we must use raw `curl` with pre-signed URLs.*

## Prerequisites

1. The user must be authenticated with the Fulcra CLI.
2. The agent's `MEMORY.md` must exist in the workspace.

## Under the Hood: The 2-Step Upload Flow

Because Fulcra securely proxies object storage (like Google Cloud Storage or S3), file uploads are a two-step process:

1. **Request a pre-signed URL** by POSTing the file's metadata to the API.
2. **PUT the file** directly to the returned URL.

Here is the exact underlying logic:

```bash
# Get the bearer token
TOKEN=$(uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth print-access-token)

# Step 1: Request Upload URL
RESPONSE=$(curl -s -X POST "https://api.fulcradynamics.com/input/v1/file_upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content_length": 399,
    "content_type": "text/markdown",
    "name": "MEMORY.md",
    "path": "/agent-memory"
  }')

UPLOAD_URL=$(echo "$RESPONSE" | jq -r '.url')

# Step 2: Upload Data
curl -s -X PUT "$UPLOAD_URL" \
  -H "Content-Type: text/markdown" \
  -H "Content-Length: 399" \
  --data-binary "@/home/leif/.openclaw/workspace/MEMORY.md"
```

## Usage

You can use the bundled `scripts/upload_memory.sh` script to automate this entire flow.

By default, running it with no arguments will sync `/home/leif/.openclaw/workspace/MEMORY.md` to the `/agent-memory` folder on Fulcra.

```bash
# Upload default MEMORY.md to a custom folder
./scripts/upload_memory.sh "/home/leif/.openclaw/workspace/MEMORY.md" "/custom-folder"
```

## Initialization (For New Users)

Before an agent can push or pull memory state, the folder structure must exist in the user's Fulcra account. 
Since cloud storage systems (like Google Cloud Storage) don't have explicit `mkdir` endpoints, we initialize the structure by uploading 0-byte `.keep` placeholder files into the desired paths.

You can use the `init_folders.sh` script to instantly scaffold this structure for a brand new user:

```bash
# Initialize the default structure at /agent-memory
./scripts/init_folders.sh

# Or initialize it at a custom path
./scripts/init_folders.sh "/custom-memory-folder"
```

## Automated Syncing and Retrieval

To make life as frictionless as possible for agents, we recommend using the automated sync scripts to maintain a clear folder structure:

```text
/agent-memory
├── latest/
│   └── MEMORY.md          (Always the most up-to-date state)
└── backups/
    ├── 20260512T215631Z/  (Immutable historical snapshots)
    │   └── MEMORY.md
    └── 20260513T000000Z/
        └── MEMORY.md
```

### Backing Up (Push)

To automatically upload a timestamped snapshot to `backups/` **and** overwrite the `latest/` pointer in one command:

```bash
./scripts/sync_state.sh "/home/leif/.openclaw/workspace/MEMORY.md"
```

### Restoring (Pull)

If an agent wakes up fresh and needs to load the most recent `MEMORY.md` state from Fulcra down to its local workspace:

```bash
./scripts/pull_latest.sh "/home/leif/.openclaw/workspace/MEMORY.md"
```