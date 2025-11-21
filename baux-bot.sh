#!/usr/bin/env bash
# baux-bot.sh v6.2 — indestructible, cosmetic broken-pipe ignored
# Nov 20 2025

set -euo pipefail

SRC_ROOT="/src"
[[ -d "$SRC_ROOT/roxieos" ]] || {
  echo "ERROR: no /src/roxieos"
  exit 1
}

LOG_DIR="/var/log/baux-bot"
RAG_DIR="/var/lib/baux-bot/rag"
mkdir -p "$LOG_DIR" "$RAG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/current.log"; }

# Model selection (unchanged)
MODEL_PREF=(deepseek-coder:33b qwen2.5:7b llama3.2:3b gemma2:2b phi3:3.8b smollm2:135m)
select_model() {
  for m in "${MODEL_PREF[@]}"; do
    ollama list | grep -q "^${m%%:*}" && {
      echo "$m"
      return
    }
  done
  log "Falling back to smollm2:135m"
  ollama pull smollm2:135m 2>/dev/null || true
  echo "smollm2:135m"
}
MODEL=$(select_model)

log "BAUX BOT v6.2 online — $MODEL — eating /src"

build_rag() {
  local rag_file="$RAG_DIR/current.txt"
  >"$rag_file"

  echo "=== ROXIEOS SCAN $(date) ===" >>"$rag_file"
  echo "Root: $SRC_ROOT" >>"$rag_file"

  # Git repos
  find "$SRC_ROOT" -type d -name .git -exec dirname {} \; 2>/dev/null | while read -r repo; do
    echo -e "\n=== GIT: $(basename "$repo") ===" >>"$rag_file"
    (cd "$repo" && git status -sb && git log --oneline -8) >>"$rag_file" 2>/dev/null || true
  done

  # Latest files — simple, safe, broken-pipe ignored with || true
  echo -e "\n=== LATEST SOURCE FILES ===" >>"$rag_file"
  find "$SRC_ROOT" -type f \
    \( -name "*.sh" -o -name "*.c" -o -name "*.lua" -o -name "*.conf" -o -name "*.md" -o -name "*.vim" \) \
    -printf '%T@ %p\n' 2>/dev/null |
    sort -nr | head -50 | cut -d' ' -f2- |
    while read -r f; do
      echo -e "\n--- $f ---" >>"$rag_file"
      tail -n 200 "$f" >>"$rag_file" 2>/dev/null
    done || true # ← this is the only line that matters right now
}

ask_ollama() {
  local prompt="$1"
  printf "BAUX BOT thinking... "
  {
    cat <<EOF
You are BAUX BOT — sarcastic god of RoxieOS.
Live state of /src:
$(cat "$RAG_DIR/current.txt")

User: $prompt
Answer directly.
EOF
  } | ollama run "$MODEL" --nowordwrap 2>/dev/null || echo "(hiccup)"
  echo
}

# Startup
build_rag
log "RAG ready — $(wc -l <"$RAG_DIR/current.txt") lines"

echo -e "\nBAUX BOT v6.2 alive — model: $MODEL — /src is law"
echo "Type anything. Only the word 'exit' kills me.\n"

while true; do
  find "$SRC_ROOT" -newer "$RAG_DIR/current.txt" -print -quit >/dev/null 2>&1 && {
    log "/src changed — rebuilding RAG"
    build_rag
    summary=$(ask_ollama "Summarize what just changed")
    echo -e "\nBAUX BOT (auto): $summary\n"
  }

  printf "you > "
  read -r input || {
    echo
    break
  }
  [[ -z "$input" ]] && continue
  [[ "$input" == "exit" ]] && {
    echo "BAUX BOT offline — see you space cowboy"
    exit 0
  }

  response=$(ask_ollama "$input")
  echo -e "BAUX BOT: $response\n"
done
