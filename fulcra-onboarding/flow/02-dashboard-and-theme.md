# Step 5: The Dashboard Canvas & Theming

Once the safety infrastructure (Memory Sync and Milestone Annotations) is confirmed, it is time to build the UI!

1. **Introduce the Dashboard:**
   - Tell the user that these two new data streams (Memory Backups and Annotations) are the perfect starting point for their new graphical dashboard. You will build a timeline view to visualize them.
   - Explain that you are about to scaffold the SvelteKit dashboard locally.

2. **The Theming Question:**
   - Say: *"I want to make sure the dashboard looks exactly the way you want it to. What kind of visual genre or theme do you prefer?"*
   - Provide a few distinct examples:
     - Sleek Sci-Fi (Dark mode, neon accents, monospaced fonts)
     - High Fantasy (Parchment textures, serif fonts, gold/brown accents)
     - Modern Minimalist (Lots of whitespace, sans-serif, clean lines)
     - Frank Lloyd Wright (Earthy tones, geometric layouts, stained glass motifs)
   - Offer them the option to pick one of those, describe their own, or let you choose something completely random and fun.
   
3. **Wait for their theme choice.**

# Step 6: Scaffolding and Launching

1. **Acknowledge and Begin:**
   - Acknowledge their theme choice.
   - Tell them: *"Excellent choice. I am going to scaffold the Svelte app, write the custom CSS for that theme, and wire up the timeline components. This will just take me a minute or two. I will let you know as soon as it is ready!"*

2. **Execute the Build (No user prompt required here, just act):**
   - Execute the `fulcra-skills-dashboard` scaffolding script. *Generate a unique target directory name each time so you don't collide with previous test runs (e.g., `fulcra-dashboard-<timestamp>`).*
   - Write the Svelte components (`+page.svelte`) to mock or ingest the Memory/Annotation data into a timeline.
   - **Important:** Add the `AgentChat.svelte` component (from `templates/AgentChat.svelte`) into the dashboard so the user can continue talking to you directly from the UI. Hook its webhook URL up to your active OpenClaw listener (e.g., the `royal-decrees` webhook).
   - Apply CSS corresponding to their chosen theme.
   - Start the Svelte dev server (`npm run dev -- --host &`).

3. **Deliver the Keys:**
   - Reply to the user that the dashboard is live.
   - Provide the exact local URL and Port (e.g., `http://localhost:5173`).
   - **Crucial:** Provide the exact SSH command they need to forward the port if they are running the agent remotely. 
     - Example: `ssh -L 5173:localhost:5173 user@remote-ip`