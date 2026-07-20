# cross-model-handoff

<p align="center">
  <b>English</b> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

## Keep one project moving across multiple AI tools

Do you use IDEs such as VS Code, Antigravity, or Cursor, and CLIs such as Claude Code or Codex to build software or create other things with AI?

When you move between AI tools, cross-model-handoff carries the project's context and intent with you. Run `/handoff` before clearing a chat or switching tools, and the AI generates a ready-to-paste handoff prompt for the next AI. It works with Claude Code, Codex, Gemini CLI, Antigravity, Cursor, and any tool that reads `AGENTS.md`.

## For everyone

You do not need to be an engineer to use this.

### When to use it

Use cross-model-handoff when:

- You are about to clear a long AI chat.
- Your credits or context are running low.
- You want to switch from Claude Code to Codex, Gemini, or another AI tool.
- You want to stop for today and continue later.

### How to use it

1. While your work is still fresh, run /handoff.
2. It writes one small note and prints two copy-ready outputs.
3. Copy the Chat resume prompt.
4. Clear the chat or switch tools.
5. Paste the prompt into the next AI session.

The next AI gets the goal, current state, exact handoff file, next action, and the first files to read. It does not need to search through old notes or ask you which passphrase to use. You only need /handoff-list when you want to choose between multiple older threads yourself.

### What you will see

The output includes a prompt like this:

~~~text
Please resume the next task.

Project: my-app
Handoff file: .handoff/2026-07-20-fix-login.md
Goal: Fix the login error
State: The bug is reproduced; the fix is not verified
Next: Run the login test and inspect the failure
Read first: tests/login.test.ts; src/auth/login.ts
Running: none

Start with Next. Do not search other .handoff files.
~~~

Paste that block into the next AI chat. The AI can open the named handoff file only if it needs more detail.

A second output is provided for terminal users:

~~~bash
npx cross-model-handoff resume --file .handoff/2026-07-20-fix-login.md
~~~

This is another way to continue from the terminal. Choose the chat prompt or the terminal command according to your workflow.

## For engineers

The handoff note contains a short Resume Capsule at the top, followed by the detailed session record. The Capsule contains:

- Project and exact handoff file
- Repo-prefixed passphrase
- Goal and current state
- One concrete next action
- Files to read first
- Running processes, servers, ports, and worktrees

The detailed note remains the source of truth and stays under 80 lines. Existing notes without a Resume Capsule still work through their passphrase and /handoff-list.
## The problem

Working across multiple AI coding tools, two things bite constantly:

- **Credits run out mid-task.** You switch tools and lose all context. Re-explaining costs as much as redoing the work.
- **Context bloats.** The longer a session runs, the less reliable the model gets. Waiting for auto-compaction means the summary is written at the model's *worst* moment.

Most fixes are heavy — a wiki, a status-doc protocol, a synced vault. This isn't. It's three plain files.

## How it works

1. **`.handoff/`** — one short markdown note per session, in the project root.
2. **A passphrase** — formatted `{repo-name}: {memorable phrase}` in each note, so you resume the *right* thread by name and always know which project it belongs to (matters when parallel sessions share a branch, or when you juggle many repos).
3. **`AGENTS.md`** — the one config file 60+ AI tools already read. It points any tool at the latest note. Nothing here is Claude-specific.

## Install

**Claude Code (plugin).** Inside a `claude` session — not a plain terminal:

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

**Any other tool (manual).** Paste [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md) into your agent and say "set up cross-model handoff here." It scaffolds `.handoff/` + `AGENTS.md`. No plugin runtime needed — works in Codex, Gemini CLI, Antigravity, Cursor, or any IDE chat.

<details>
<summary><code>/plugin</code> not working?</summary>

| Where you typed it | Fix |
|---|---|
| Plain terminal (`zsh: no such file or directory: /plugin`) | It's not a shell command. Run `claude` first, then type it in that session. |
| An IDE's built-in AI chat / Antigravity panel (`/plugin isn't available in this environment`) | That panel isn't the real Claude Code runtime. Use the manual setup above. |
</details>

## Commands

| Command | What it does |
|---|---|
| `/handoff` | Write one note to `.handoff/`, then print a copy-ready Chat resume prompt and terminal command. The note includes passphrase, what was done, current state, **running state**, and next step. Then it's safe to `/clear`. |
| `/handoff-list` | Fallback: list older passphrases in `.handoff/` so you can choose a thread manually. |
| `/handoff-setup` | Scaffold `.handoff/` + `AGENTS.md` in a project. Run once per project. |

Plus two hooks — `SessionStart` (auto-lists your passphrases on resume) and `PreCompact` (a safety net). Both are harness-only: zero added context cost.

## The daily loop

1. **Work normally.** Nothing to maintain. Git commits are the source of truth.
2. **Before you clear or switch tools:** `/handoff`. Do it proactively — don't wait for context to fill up.
3. **Coming back, in any tool:** paste the Chat resume prompt. Use `/handoff-list` only when you need to choose an older thread manually.

## Why write the note proactively

Auto-compaction only fires when context is nearly full — when the model is least reliable. If the `PreCompact` hook is your only trigger, the *worst* version of the model writes the note the next session depends on. Run `/handoff` early; treat the hook as a fallback you hope never fires.

## Example note

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes-app: shoes is green, next is landing Moments"

## What was done
- Device selector for shoes moment (components/moments/moment-frame.tsx)

## Current state
- Verified: typecheck passes, visual parity green
- Not verified: mobile breakpoint untested

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees: .claude/worktrees/cg-pipeline (mid-task, do not delete)

## Next step
1. Wire landing page Moments band to live data

## Files to read next
- components/moments/moment-frame.tsx
```

## Why not a tool's built-in memory?

Because it doesn't travel. Claude Code's memory is useless the moment you switch to Codex. `AGENTS.md` + `.handoff/` are just files — they work everywhere, with no per-tool integration to build.

## License

MIT
