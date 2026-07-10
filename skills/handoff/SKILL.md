---
name: handoff
description: Write ONE handoff note to .handoff/, then it's safe to /clear
---

Write ONE handoff note to `.handoff/{YYYY-MM-DD}-{task-slug}.md` in the project root. Create `.handoff/` if it doesn't exist.

The note must contain:
1. **Passphrase** — always in the form `{repo-name}: {memorable phrase}`, e.g. `myapp-api: 青い月曜日`. The repo name is required and goes FIRST so that when you read the passphrase later you instantly know which project it belongs to; without it, notes from different repos are indistinguishable. Derive the repo name from `basename "$(git rev-parse --show-toplevel)"` (fall back to the project root directory name if it's not a git repo). Older notes in this project may use the label 合言葉 and may omit the repo name — same meaning, kept for backward compatibility.
2. What was done (with file paths)
3. Current state (what's verified, what's not)
4. Running state — background processes started this session (shell ID + kill command), dev servers/ports, open worktrees or branches. Write "none" if nothing is running; don't omit this section.
5. Next concrete step
6. Files to read next

Keep it under 80 lines. Do NOT update any other files. One file only.

After writing, tell the user in Japanese:
> ハンドオフノートを書きました。`/clear` しても安全です。
> Passphrase: 『{repo-name}: {keyword}』（先頭は必ずリポジトリ名 — どのプロジェクトか一目で分かるように）
> モデルを切り替える場合: 新しいツールで「AGENTS.mdを読んで、.handoff/の最新ノートから再開して」と言えば続きから。
> 合言葉リストを見たい場合は `/handoff-list` で一覧できます。

Keep it brief.
