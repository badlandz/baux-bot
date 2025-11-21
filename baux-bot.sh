#!/usr/bin/env bash
# baux-bot.sh v5.0 — RoxieOS monorepo edition (final)
# Hard-coded to /src/roxieos — knows baux + bauxwm + everything
# Nov 20 2025

set -u
set -o pipefail

# ── Fixed monorepo root (everything lives here) ───────────────────────
ROXIE_ROOT="/src/roxieos"
if [[ ! -d "$ROXIE_ROOT" ]]; then
  echo "ERROR: RoxieOS monorepo not found at $ROXIE_ROOT"
  exit 1
fi

LOG_DIR="$ROXIE_ROOT/bot/chatlogs"
RAG_DIR="$ROXIE_ROOT/bot/rag"
mkdir -p "$LOG_DIR" "$RAG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_DIR/current.log"; }

# ── Model selection + auto-pull ───────────────────────────────────────
MODEL_PREF=(deepseek-coder:33b qwen2.5:7b llama3.2:3b gemma2:2b phi3:3.8b smollm2:135m)
select_and_pull_model() {
  for m in "${MODEL_PREF[@]}"; do
    if ollama list | grep -q "^${m%%:*}"; then
      echo "$m"
      return
    fi
  done
  log "No preferred model — pulling smollm2:135m (tiny & fast)"
  ollama pull smollm2:135m
  echo "smollm2:135m"
}

MODEL=$(select_and_pull_model)
log "BAUX BOT v5.0 online — using $MODEL — scanning full RoxieOS monorepo"

# ── Full monorepo RAG (baux + bauxwm + neovim-roxanne + live-build) ───
build_monorepo_rag() {
  local rag_file="$RAG_DIR/current.txt"
  >"$rag_file"

  echo "=== ROXIEOS MONOREPO SCAN ($(date)) ===" >>"$rag_file"
  echo "Root: $ROXIE_ROOT" >>"$rag_file"
  echo "Projects: baux, bauxwm, neovim-roxanne, live-build configs" >>"$rag_file"

  # Git status for all sub-repos
  for repo in "$ROXIE_ROOT"/packages/* "$ROXIE_ROOT"/live; do
    [[ -d "$repo/.git" ]] || continue
    echo -e "\n=== GIT STATUS: $(basename "$repo") ===" >>"$rag_file"
    (cd "$repo" && git status -sb && git log --oneline -5) >>"$rag_file" 2>/dev/null || true
  done

  # All source files — latest first, full paths
  echo -e "\n=== LATEST SOURCE FILES (full monorepo) ===" >>"$rag_file"
  find "$ROXIE_ROOT" -type f \
    \( -name "*.sh" -o -name "*.conf" -o -name "*.lua" -o -name "*.md" -o -name "*.toml" \
    -o -name "*.c" -o -name "*.h" -o -name "Makefile" -o -name "*.patch" \) \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -40 | cut -d' ' -f2- |
    while read -r f; do
      echo -e "\n--- $f ---" >>"$rag_file"
      tail -200 "$f" 2>/dev/null >>"$rag_file"
    done
}

ask_ollama() {
  local prompt="$1"
  local rag_file="$RAG_DIR/current.txt"

  printf "BAUX BOT thinking... "
  {
    cat <<EOF
You are BAUX BOT — elite, sarcastic coding assistant for the full RoxieOS monorepo.
You have live access to every file in /root/roxieos (baux, bauxwm, neovim-roxanne, live-build, etc.).

Current state:
$(cat "$rag_file")

User: $prompt

Answer directly and conversationally. Use code blocks and paths when relevant.
EOF
  } | ollama run "$MODEL" --nowordwrap 2>/dev/null || echo "(model hiccup — retrying...)"
  echo
}

# ── Startup ───────────────────────────────────────────────────────────
build_monorepo_rag
log "Monorepo RAG ready (~$(wc -l <"$RAG_DIR/current.txt") lines)"
echo -e "\nBAUX BOT v5.0 ready (model: $MODEL) — full RoxieOS awareness"
echo "Type message — only the word 'exit' quits.\n"

while true; do
  # Rebuild on any change in the monorepo
  if find "$ROXIE_ROOT" -newer "$RAG_DIR/current.txt" -print -quit >/dev/null 2>&1; then
    log "Monorepo changed — rebuilding RAG"
    build_monorepo_rag
    summary=$(ask_ollama "Summarize what just changed across the RoxieOS monorepo.")
    echo -e "\nBAUX BOT (auto): $summary\n"
  fi

  printf "you > "
  read -r input || {
    echo
    break
  }
  [[ -z "$input" ]] && continue
  [[ "$input" == "exit" ]] && {
    echo "BAUX BOT offline — see you space cowboy 🤠"
    exit 0
  }

  response=$(ask_ollama "$input")
  echo -e "BAUX BOT: $response\n"
done
