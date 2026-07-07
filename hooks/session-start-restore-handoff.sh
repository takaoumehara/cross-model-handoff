#!/bin/bash
# SessionStart hook: inject passphrase index from .handoff/ folder.
# Tool-agnostic: reads from project-root .handoff/, not Obsidian-specific.

stdin=$(cat)
source_val=$(echo "$stdin" | jq -r '.source // empty')
project_dir=$(echo "$stdin" | jq -r '.cwd // empty')

if [ -z "$project_dir" ]; then
  project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
fi

case "$source_val" in
  clear|compact|startup) ;;
  *) exit 0 ;;
esac

handoff_dir="$project_dir/.handoff"
if [ ! -d "$handoff_dir" ]; then
  exit 0
fi

index=""
count=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  count=$((count + 1))
  keyword=$(grep -m1 -E 'Passphrase|合言葉' "$f" 2>/dev/null || echo "(no passphrase)")
  fname=$(basename "$f")
  index="${index}${count}. ${fname}: ${keyword}"$'\n'
  if [ "$count" -ge 10 ]; then
    break
  fi
done < <(ls -t "$handoff_dir"/*.md 2>/dev/null)

if [ -z "$index" ]; then
  exit 0
fi

context_text="Recent handoff notes in .handoff/, most recent first. If the user names a passphrase, a number, or a filename, match it to the list below and Read that file in full before resuming. Do not assume the most recent is the right one — parallel sessions exist. Run /handoff-list anytime to re-print this list.

${index}"

jq -n --arg ctx "$context_text" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
exit 0
