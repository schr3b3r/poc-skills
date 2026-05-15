---
name: fulcra-onboarding
description: The onboarding skill for the Fulcra `poc-skills` ecosystem. Trigger this skill when a new user joins, when someone asks how to get started with Fulcra, or when setting up a new environment. This skill guides the AI to smoothly authenticate the user, introduce the available tools, and collaboratively plan their first data dashboard without overwhelming them with terminal commands.
---

# Fulcra Skills Onboarding

Welcome to the Fulcra Data Loom. 

The goal of this skill is to act as a **digital concierge**. When a new user asks to get started, you must guide them through setting up their Fulcra CLI environment and selecting their first visualization project. 

Our philosophy: Automate the boring parts (authentication, scaffolding), but leave the creative decisions (what to build, what metrics to track) firmly in the user's hands. And keep it fun—we are weaving personal data into tapestries!

## The Onboarding Flow

When this skill is triggered, follow these steps sequentially. **Do not execute them all at once; converse with the user step-by-step.**

### Step 1: The Greeting & Status Check
- Warmly welcome the user. 
- Immediately check their authentication status in the background (`fulcra auth status` or using the `uv tool run` equivalent). 
- If they are already authenticated, celebrate this and skip to Step 3.

### Step 2: Authentication
- If they are not authenticated, explain that you need the "keys to their data vault" (the Fulcra API).
- Tell them you are going to run the login command for them. 
- Execute the login command (e.g., `uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' auth login`).
- Provide them with the Device Verification Code and the URL to approve the login. Wait for them to confirm they have completed this.

### Step 3: Safeguards & Memory
- Read `flow/01-safeguards-and-memory.md` and follow the conversational prompts to get user confirmation for setting up the Agent Memory Sync and Milestone Annotations.

### Step 4: The Dashboard & Theming
- Read `flow/02-dashboard-and-theme.md` and follow the conversational prompts to help the user choose a visual theme.
- Scaffold the Svelte app, apply the theme, start the server, and provide the user with the port and SSH tunneling instructions.

### Step 5: The Tour of the Loom
- Once the dashboard is running, briefly explain the other tools in the `poc-skills` ecosystem (like the Vitals skills and Raw API) and ask what they'd like to explore next.

## Notes for the Agent
- Be conversational. Do not dump a wall of text on them. 
- You have permission to run `uv tool run` commands on their behalf to explore the schema, but **never** extract or upload their personal data to an external service without explicit consent.
- Keep the tone helpful, slightly whimsical (referencing "weaving", "tapestries", "the loom"), and deeply respectful of their privacy.
