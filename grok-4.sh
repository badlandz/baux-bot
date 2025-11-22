#!/bin/bash
PAYLOAD="$1"
QUESTION=$(echo "$PAYLOAD" | jq -r '.question')
CONTEXT=$(echo "$PAYLOAD" | jq -r '.context')

curl -s https://api.x.ai/v1/chat/completions \
  -H "Authorization: Bearer $GROK_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "grok-4",
    "messages": [
      {"role": "system", "content": "You are helping build RoxieOS. Use the provided README-GROK.md context when relevant."},
      {"role": "user", "content": "'"${CONTEXT:0:8000}"'\n\nQuestion: '"${QUESTION}"'"}
    ],
    "temperature": 0.2
  }' | jq -r '.choices[0].message.content'
