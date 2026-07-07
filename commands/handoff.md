---
description: Write ONE handoff note to .handoff/, then it's safe to /clear
---

Write ONE handoff note to `.handoff/{YYYY-MM-DD}-{task-slug}.md` in the project root. Create `.handoff/` if it doesn't exist.

The note must contain:
1. **Passphrase** (a short, memorable phrase to resume this exact thread — older notes in this project may use the label 合言葉, same meaning, kept for backward compatibility)
2. What was done (with file paths)
3. Current state (what's verified, what's not)
4. Running state — background processes started this session (shell ID + kill command), dev servers/ports, open worktrees or branches. Write "none" if nothing is running; don't omit this section.
5. Next concrete step
6. Files to read next

Keep it under 80 lines. Do NOT update any other files. One file only.

After writing, tell the user in Japanese:
> ハンドオフノートを書きました。`/clear` しても安全です。
> Passphrase: 『{keyword}』
> モデルを切り替える場合: 新しいツールで「AGENTS.mdを読んで、.handoff/の最新ノートから再開して」と言えば続きから。
> 合言葉リストを見たい場合は `/handoff-list` で一覧できます。

Keep it brief.
