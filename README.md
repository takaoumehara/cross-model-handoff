# cross-model-handoff

<p align="center">
  <b>English</b> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

Passphrase-based session handoff for multi-agent coding workflows. Write one note before you clear context or switch tools — resume instantly by name, in Claude Code, Codex, Gemini CLI, Antigravity, Cursor, or anything else that reads `AGENTS.md`.

## The problem

If you work across multiple AI coding tools — say Claude Code, Codex, Gemini, and Antigravity in the same week — you run into two things constantly:

- **Credits run out mid-task** on one tool. You switch to another and lose all context. Re-explaining what you were doing costs as much as just doing it again.
- **Context windows bloat.** The longer a session runs, the less reliable the model gets — retrieval accuracy measurably drops as a window fills up. Waiting for auto-compaction to summarize means the summary gets written at the exact moment the model is least sharp.

Most fixes for this are heavy: a wiki, a status-doc protocol, a vault synced across sessions. That itself becomes a tax — one report put it at 65,000+ tokens read per session just to catch up on state files, before doing any actual work.

## The idea

Three small pieces, no external system:

1. **`.handoff/`** — a plain-markdown folder in the project root. One short note per session, written right before you clear or switch tools.
2. **A passphrase** — a short, memorable phrase in each note, so you can say "resume from *that* thread" instead of guessing which file is relevant. This matters once you have parallel sessions on the same branch.
3. **`AGENTS.md`** — the one config file already read by 60+ AI coding tools. It tells any tool: read the latest `.handoff/` note first, don't touch legacy state files, write one note before you leave.

Nothing here is Claude-specific. `AGENTS.md` + `.handoff/*.md` is just files in a git repo — any tool that can read a file can use it.

## Install

### As a Claude Code plugin

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

This wires up two commands and two hooks automatically (see below).

### Manually, for any tool

Copy `skills/cross-model-handoff-setup/SKILL.md` into your project (or just paste its setup steps to your agent) — it will scaffold `.handoff/` and `AGENTS.md` for you. Everything after that is plain markdown; no plugin required.

## What you get

| | |
|---|---|
| `/handoff-and-clear` | Writes one note to `.handoff/{date}-{slug}.md` with a passphrase, what was done, current state, **running state** (background processes, dev servers, open worktrees — the stuff `git log` can't tell you), next step, and files to read next. Then it's safe to `/clear`. |
| `/handoff-list` | Scans `.handoff/` and prints a numbered list of passphrases so you can just pick one instead of re-reading every file. |
| `SessionStart` hook | On `clear`/`compact`/`startup`, auto-injects that same numbered index into context — resuming is often just "continue #3" or naming the passphrase. |
| `PreCompact` hook | Safety net: forces one handoff note to be written if context is about to auto-compact. **Not the primary path** — see below. |

## On trigger timing (read this)

Auto-compaction fires when context is nearly full — i.e., when the model is at its least reliable (thinking depth and retrieval accuracy both measurably degrade as a window fills). If you rely on the `PreCompact` hook as your only handoff trigger, you're asking the most degraded version of the model in your session to write the note the *next* session depends on.

Treat `/handoff-and-clear` as something you run **proactively**, earlier in a session, whenever you're about to switch tasks or tools. Treat the `PreCompact` hook as the emergency fallback you hope never fires.

## Example note

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- Implemented device selector for shoes moment (components/moments/moment-frame.tsx)
- Fixed cx() type errors in P3 browse screen

## Current state
- Verified: typecheck passes, visual parity script green
- Not verified: mobile breakpoint untested

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees/branches: .claude/worktrees/cg-pipeline (mid-task, do not delete)

## Next step
1. Wire landing page Moments band to live data

## Files to read next
- components/moments/moment-frame.tsx
- app/[locale]/moments/page.tsx
```

## Why not just use one tool's built-in memory?

Because it doesn't travel. A Claude Code project memory doesn't help when you switch to Codex because you ran out of credits. `AGENTS.md` + `.handoff/` is the smallest thing that works everywhere, because it's just files — no per-tool integration to build or maintain.

## License

MIT
