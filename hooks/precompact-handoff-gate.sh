#!/bin/bash
# PreCompact hook: before context is compacted, force ONE handoff note.
# Blocks once per session. Writes to .handoff/ in project root (tool-agnostic).

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
project_dir=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$project_dir" ] && project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

marker="/tmp/.claude-handoff-gate-${session_id}"
if [ -f "$marker" ]; then
  exit 0
fi
touch "$marker"

handoff_dir="$project_dir/.handoff"
mkdir -p "$handoff_dir"

reason="Context is about to be compacted. Write ONE handoff note to: ${handoff_dir}/{YYYY-MM-DD}-{task-slug}.md

The note must contain: Passphrase (short memorable phrase to resume this thread), what was done, current state, running state (background processes/dev servers/worktrees — say \"none\" if nothing), next step. That's it — do NOT update any other files. One file only, then proceed."

jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
exit 0
