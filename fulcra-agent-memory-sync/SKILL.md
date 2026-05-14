---
name: fulcra-agent-memory-sync
description: Temporary skill to upload the agent's MEMORY.md file and its daily logs (memory/) directly to the Fulcra cloud file storage. Uses the undocumented file upload endpoints to securely sync agent context to the user's Fulcra account.
---

# Fulcra Agent Memory Sync (Temporary)

This is a temporary workaround skill designed to back up agent memory and contextual files directly to Fulcra's cloud file storage endpoints. This allows agents to persist their entire state (`MEMORY.md` and the `memory/` daily logs directory) to a safe remote location and decouple it from local machine lifecycles.

*Note: The Fulcra CLI will eventually support file operations natively. Until then, we must use raw `curl` with pre-signed URLs.*

## Prerequisites

1. The user must be authenticated with the Fulcra CLI.
2. The agent's `MEMORY.md` or `memory/` directory must exist in the workspace.

## Under the Hood: The Upload Flow

Because Fulcra securely proxies object storage (like Google Cloud Storage or S3), file uploads are a two-step process:

1. **Request a pre-signed URL** by POSTing the file's metadata to the API.
2. **PUT the file** directly to the returned URL.

We package the entire memory state (`MEMORY.md` + `memory/`) into a single `memory_archive.tar.gz` tarball so that directory structure and daily logs are preserved flawlessly across environments.

## Initialization (For New Users)

Before an agent can push or pull memory state, the folder structure must exist in the user's Fulcra account. 
Since cloud storage systems (like Google Cloud Storage) don't have explicit `mkdir` endpoints, we initialize the structure by uploading 0-byte `.keep` placeholder files into the desired paths.

You can use the `init_folders.sh` script to instantly scaffold this structure for a brand new user:

```bash
# Initialize the default structure at /agent-memory
./scripts/init_folders.sh
```

## Automated Syncing and Retrieval

To make life as frictionless as possible for agents, we recommend using the automated sync scripts to maintain a clear folder structure:

```text
/agent-memory
├── latest/
│   └── memory_archive.tar.gz          (Always the most up-to-date state)
└── backups/
    ├── 20260512T215631Z/  (Immutable historical snapshots)
    │   └── memory_archive.tar.gz
    └── 20260513T000000Z/
        └── memory_archive.tar.gz
```

### Backing Up (Push)

To automatically package your local `MEMORY.md` and `memory/` directory into a tarball, upload a timestamped snapshot to `backups/`, **and** overwrite the `latest/` pointer in one command:

```bash
./scripts/push_memory.sh
```

### Restoring (Pull)

If an agent wakes up fresh on a new VM and needs to load the most recent memory archive from Fulcra down to its local workspace (which will extract `MEMORY.md` and the `memory/` directory):

```bash
./scripts/pull_memory.sh
```
