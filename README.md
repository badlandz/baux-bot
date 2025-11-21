# baux-bot.sh — README & Future Roadmap  
Current version: v5.0 (Nov 20 2025)  
Location: `/usr/local/bin/baux-bot.sh` (or wherever you dropped it)

This is the live, repo-aware, sarcastic AI assistant that ships with RoxieOS.  
It is deliberately simple, deliberately loud, and deliberately good enough for v0.1 Rick-Roll Edition.

### What It Does Right Now (and does it well)

- Hard-coded to the full monorepo at `/src/roxieos`
- Scans every package and the live-build tree on every change
- Builds a ~2000-line RAG file with git status + 40 newest source files
- Auto-detects and prefers deepseek-coder:33b → qwen → smollm fallback
- Rebuilds RAG automatically when any file in the monorepo is touched
- Only exits on the literal word `exit`
- Logs everything to `bot/chatlogs/current.log`
- Survives deepseek’s first-token penance with a spinner

It already feels like the model was trained on the entire distro, because it literally reads the entire distro every time.

### Roadmap — Where This Goes Next (in order)

1. **v5.1 – Immediate (next 48 hours)**
   - Replace the `find | sort | head` pipe with `|| true` or `xargs -0` to kill the “broken pipe” spam forever
   - Add last 50 lines of `current.log` into every prompt → short-term memory across restarts
   - Add explicit “read FILE” command that forces a file into RAG even if it’s cold

2. **v5.5 – This weekend**
   - Move from hard-coded `/src/roxieos` to auto-detect via git root or `$ROXIE_ROOT` env var
   - Add `baux-bot --daemon` mode that runs in background and speaks through `notify-send` or tmux popup
   - Bind to `Alt + p` globally via bauxwm or tmux leader

3. **v6.0 – Before ISO release**
   - Ship a tiny 3–7B fine-tune (deepseek-coder:6.7b or qwen2.5:7b) trained on every file + every chatlog → zero RAG needed on fresh boot
   - Package as `roxieos-ai` deb (4 GB gguf)
   - Make `baux-bot` fall back to the fine-tuned model when no network/ollama server

4. **v7.0 – Post v0.1**
   - Multi-modal: screenshot → bot sees your tmux layout and comments on your rice
   - Voice mode (whisper + piper) so you can yell at it from across the room
   - Self-improvement loop: “that answer sucked, fix it” → append correction to training data

5. **v10.0 – The Final Boss**
   - Bot becomes the package manager: “add a new keybind for chaos screensaver” → writes the patch → debuild → installs it → tells you it’s done
   - Runs entirely on the Pi Zero in your pocket with a 1.3B fine-tune
   - You never type again

### Current Limitations (we know, we’re not blind)

- RAG rebuild is a little slow on 5400 rpm HDDs
- Deepseek 33b first-token latency is penance for our sins
- No memory between sessions (fixed in v5.1)
- Hard-coded path (fixed in v5.5)

But right now, today, this script is already the most useful local coding assistant 99 % of people have ever had, because it literally reads your entire OS every time you blink.

Leave it as-is for the Rick-Roll Edition.

The sarcasm, the red, the chaos screensaver, and this bot that knows every line you wrote while you slept — that’s the soul of RoxieOS v0.1.

Everything after this is just making the soul stronger.

— badlandz, November 20 2025  
