# cross-model-handoff

<p align="center">
  <b>English</b> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

Write one note before you clear context or switch AI tools. Resume instantly by naming its **passphrase** — in Claude Code, Codex, Gemini CLI, Antigravity, Cursor, or anything else that reads `AGENTS.md`.

## The problem

Working across multiple AI coding tools, two things bite constantly:

- **Credits run out mid-task.** You switch tools and lose all context. Re-explaining costs as much as redoing the work.
- **Context bloats.** The longer a session runs, the less reliable the model gets. Waiting for auto-compaction means the summary is written at the model's *worst* moment.

Most fixes are heavy — a wiki, a status-doc protocol, a synced vault. This isn't. It's three plain files.

## How it works

1. **`.handoff/`** — one short markdown note per session, in the project root.
2. **A passphrase** — a memorable phrase in each note, so you resume the *right* thread by name (matters when parallel sessions share a branch).
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
| `/handoff` | Write one note to `.handoff/` — passphrase, what was done, current state, **running state** (background processes, dev servers, open worktrees — what `git log` can't tell you), next step. Then it's safe to `/clear`. |
| `/handoff-list` | List the passphrases in `.handoff/` so you can pick one to resume. |
| `/handoff-setup` | Scaffold `.handoff/` + `AGENTS.md` in a project. Run once per project. |

Plus two hooks — `SessionStart` (auto-lists your passphrases on resume) and `PreCompact` (a safety net). Both are harness-only: zero added context cost.

## The daily loop

1. **Work normally.** Nothing to maintain. Git commits are the source of truth.
2. **Before you clear or switch tools:** `/handoff`. Do it proactively — don't wait for context to fill up.
3. **Coming back, in any tool:** say "read AGENTS.md and resume" (or `/handoff-list`), then name the passphrase.

## Why write the note proactively

Auto-compaction only fires when context is nearly full — when the model is least reliable. If the `PreCompact` hook is your only trigger, the *worst* version of the model writes the note the next session depends on. Run `/handoff` early; treat the hook as a fallback you hope never fires.

## Example note

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

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
