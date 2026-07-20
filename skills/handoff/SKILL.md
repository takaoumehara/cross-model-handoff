---
name: handoff
description: Write ONE handoff note to .handoff/, then it's safe to /clear
---

Start the note with this compact block immediately after the title:

~~~markdown
## Resume Capsule

Project: {repo-name}
Handoff: .handoff/{YYYY-MM-DD}-{task-slug}.md
Passphrase: "{repo-name}: {memorable phrase}"
Goal: {session goal}
State: {short verified/unresolved summary}
Next: {one concrete imperative next action}
Read first: {zero to three project-relative file paths}
Running: {short summary, or none}
~~~

Keep the Capsule to at most ten lines including its heading and normally under 120 words. Do not put secrets, logs, or full history in it. The detailed sections below remain required. The Capsule's Passphrase must use {repo-name}: {memorable phrase} with the repository name first. Derive the repository name from basename "$(git rev-parse --show-toplevel)", falling back to the project-root directory name if this is not a Git repository.
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

Then print these two copy-ready blocks. The first must embed the Capsule values so the next AI can start without searching .handoff/ or reading the full note:

~~~text
次の作業を再開してください。

Project: {repo-name}
Handoff file: .handoff/{YYYY-MM-DD}-{task-slug}.md
Goal: {session goal}
State: {short verified/unresolved summary}
Next: {one concrete imperative next action}
Read first:
- {path}
Running: {short summary, or none}

上記のNextをすぐ実行してください。
.handoff内の別ファイルや別の合言葉は探さないでください。
詳細が必要な場合だけ、指定したHandoff fileを参照してください。
~~~

Then print a Terminal restart command block:

~~~bash
npx cross-model-handoff resume --file .handoff/{YYYY-MM-DD}-{task-slug}.md
~~~

This is a future CLI entry point. If the CLI is unavailable, say so plainly; the chat block is the working fallback. Do not claim that the command ran.

Keep it brief.
