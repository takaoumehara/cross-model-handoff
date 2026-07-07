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

There are two ways to install this, and which one works depends on where you're typing the command. Read the troubleshooting table below if `/plugin` doesn't do what you expect — it usually means you're in a place that isn't the actual Claude Code CLI runtime.

### Method A — Claude Code plugin (terminal)

This is the officially supported path. It only works inside the real Claude Code CLI session — not in a plain shell, and not reliably inside every IDE-embedded chat panel (see the table below).

1. Open a terminal and start Claude Code:
   ```bash
   claude
   ```
   `/plugin` is a command you type **inside** this interactive session — it is not a shell command. If you run `/plugin marketplace add ...` directly at your zsh/bash prompt (or pipe it to `bash`), it fails with something like `zsh: no such file or directory: /plugin`. That error means you never entered a Claude Code session in the first place.

2. Once you're inside the Claude Code session, run:
   ```
   /plugin marketplace add takaoumehara/cross-model-handoff
   /plugin install cross-model-handoff@cross-model-handoff
   ```

This wires up two commands and two hooks automatically (see below).

### Method B — Manual setup (works everywhere, no plugin system required)

Use this if you're on Codex, Gemini CLI, Antigravity, Cursor, an IDE's own built-in AI chat, or anywhere `/plugin` isn't recognized or says something like `/plugin isn't available in this environment`.

1. Paste the contents of [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md) into your agent's chat (or just give it the raw GitHub URL and ask it to read and follow it).
2. Tell it: "Set up cross-model handoff in this project."
3. It creates `.handoff/` and `AGENTS.md` for you. Everything after that is plain markdown and plain instructions — no plugin runtime required.

Once set up, `/handoff` and `/handoff-list` aren't required either. If your tool doesn't support custom slash commands, just paste the contents of [`commands/handoff.md`](commands/handoff.md) as a plain prompt whenever you want to write a handoff note.

### Troubleshooting: where does `/plugin` actually work?

| Where you type it | What happens | What to do |
|---|---|---|
| A plain terminal prompt (zsh/bash), not inside Claude Code | `zsh: no such file or directory: /plugin` | `/plugin` is not a shell command. Run `claude` first, then type the command inside that session (Method A). |
| Inside the actual Claude Code CLI session (after running `claude`) | Works | This is the intended path. |
| An IDE's own built-in AI chat that isn't the real Claude Code engine (varies by IDE and version — some show a "Claude Code" panel that's actually a different agent harness underneath) | May say `/plugin isn't available in this environment`, or may just not recognize it as a command | Use Method B — it doesn't depend on any plugin system. |
| Antigravity's embedded "Claude Code" panel | `/plugin isn't available in this environment` | Expected — that panel runs Antigravity's own agent harness, not the Claude Code plugin runtime. Use Method B. |

## How to use it (day to day)

Once installed (Method A or B above), the whole workflow is three moments:

1. **You're working normally.** Nothing to do — no state file to maintain, no wiki to update. Git commits are the source of truth.
2. **You're about to clear context or switch tools.** Run `/handoff` (or, on Method B, just say "write a handoff note"). It writes one note to `.handoff/` with a passphrase. Do this proactively — don't wait for context to get huge.
3. **You're back, in any tool.** Say "read AGENTS.md and resume" (or `/handoff-list` if you're not sure which thread you were on). Name the passphrase, or the number, and the agent reads that note and picks up where you left off.

That's the whole loop. No dashboards, no daily upkeep.

## What you get

| | |
|---|---|
| `/handoff` | Writes one note to `.handoff/{date}-{slug}.md` with a passphrase, what was done, current state, **running state** (background processes, dev servers, open worktrees — the stuff `git log` can't tell you), next step, and files to read next. Then it's safe to `/clear`. |
| `/handoff-list` | Scans `.handoff/` and prints a numbered list of passphrases so you can just pick one instead of re-reading every file. |
| `SessionStart` hook | On `clear`/`compact`/`startup`, auto-injects that same numbered index into context — resuming is often just "continue #3" or naming the passphrase. |
| `PreCompact` hook | Safety net: forces one handoff note to be written if context is about to auto-compact. **Not the primary path** — see below. |

## On trigger timing (read this)

Auto-compaction fires when context is nearly full — i.e., when the model is at its least reliable (thinking depth and retrieval accuracy both measurably degrade as a window fills). If you rely on the `PreCompact` hook as your only handoff trigger, you're asking the most degraded version of the model in your session to write the note the *next* session depends on.

Treat `/handoff` as something you run **proactively**, earlier in a session, whenever you're about to switch tasks or tools. Treat the `PreCompact` hook as the emergency fallback you hope never fires.

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
