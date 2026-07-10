---
name: handoff-setup
description: Use when starting a new project, or when converting an existing project, to enable lightweight cross-model context handoff. Sets up .handoff/ + AGENTS.md so development continues without stopping when switching between Claude Code, Codex, Gemini CLI, Antigravity, Cursor, or any AI tool.
---

# Cross-Model Handoff Setup (Lightweight)

## Why this exists

Multi-agent workflows (Claude Code + Codex + Gemini CLI + Antigravity, etc.) hit two recurring problems:

1. **Credits run out mid-task** on one tool, and switching to another loses all context.
2. **Context windows bloat** over a long session, and the model quietly gets worse (retrieval accuracy drops as the window fills). Waiting for auto-compaction means the summary gets written at the point the model is least reliable.

This skill sets up a single lightweight convention that solves both: a plain-markdown handoff note + a passphrase, readable by any tool that reads `AGENTS.md`. No heavy status-file protocol, no per-tool config.

## What it sets up (3 things)

1. **`.handoff/` directory** in project root — session handoff notes live here (plain markdown, any tool reads them)
2. **`AGENTS.md`** in project root — universal entry point read by Claude Code, Codex, Gemini CLI, Antigravity, Cursor, Copilot, Windsurf, and 60+ tools
3. **A short session-rules block in `CLAUDE.md` / `AGENTS.md`** — tells the model NOT to read/write heavy state files, and where to look on resume

## Setup Steps

### Step 1: Create `.handoff/`

```bash
mkdir -p .handoff
echo ".handoff/" >> .gitignore
```

(Handoff notes are ephemeral session state — keep them out of git, or track them if you want a full history. Either is fine.)

### Step 2: Create `AGENTS.md`

Write `AGENTS.md` in the project root with this content (customize the project section, translate freely — the convention works in any language):

```markdown
# AGENTS.md — Universal entry point for any AI coding tool

Read by Claude Code, Codex, Gemini CLI, Antigravity, Cursor, Copilot, Windsurf, and 60+ tools.

## Resuming Work (READ THIS FIRST)

1. Read the latest file in `.handoff/` — it contains: Passphrase (formatted `{repo-name}: {memorable phrase}`, so the project is obvious at a glance), what was done, current state, running state, next step.
2. If `.handoff/` has multiple notes, ask which passphrase/thread to resume — don't assume the newest is right (parallel sessions on the same branch can exist).
3. If `.handoff/` is empty: run `git log --oneline -10` and `git diff`, then start working.
4. Do NOT read legacy status files (e.g. GLOBAL_STATUS.md, TASK_BOARD.md) if present — they waste context; this project uses `.handoff/` instead.

## Session Rules (all models)

- git commits are the only source of truth during work
- Do NOT write to any other state file during work
- When context gets heavy or the session ends: write ONE note to `.handoff/{date}-{slug}.md` with Passphrase (`{repo-name}: {memorable phrase}` — repo name first, always), state, running state, next step. Then it's safe to clear/switch tools.
- Keep handoff notes under 80 lines.

## Switching models mid-work

When credits run out, switch to any other tool and say:
> "Read AGENTS.md and resume from the latest note in .handoff/"

## Project: {PROJECT_NAME}

- **Runtime:** {tech stack}
- **Test:** {test commands}
- **Language:** {language preference}
```

### Step 3: Add a short session-rules block to `CLAUDE.md` (or your tool's config file)

```markdown
## Session workflow (lightweight, cross-model)

### On start
- Read the latest note in `.handoff/`
- If none: just check `git log --oneline -10` and start

### During the session
- Don't write to any status file. Git commits are the source of truth.

### Before clearing / compacting / switching tools
- Run `/handoff` — writes one note to `.handoff/` with a Passphrase

### Switching AI tools (e.g. out of credits)
- In the new tool: "Read AGENTS.md and resume from the latest note in .handoff/"
```

### Step 4: Wire the hooks (if not already active)

This plugin ships two hooks (see `hooks/hooks.json`):
- `PreCompact` — forces one handoff note to be written before context is compacted (safety net; see the note on trigger timing below)
- `SessionStart` (matcher: `clear|compact|startup`) — injects a numbered index of recent `.handoff/` notes and their passphrases, so you can resume by number, filename, or passphrase without re-reading every file

If you installed this as a Claude Code plugin, these are wired automatically. For other tools, translate the two hook scripts into that tool's equivalent lifecycle events, or just run `/handoff` manually.

**On trigger timing:** the `PreCompact` hook is a safety net, not the primary path. Auto-compaction (and PreCompact) fires only when context is nearly full — i.e. when the model is at its least reliable. Prefer running `/handoff` proactively earlier in a long session, whenever you're about to switch tasks or tools, rather than waiting for the hook to force it.

### Step 5: Report

Tell the user:
> Setup complete.
> - `.handoff/` and `AGENTS.md` created
> - Any AI tool can resume with: "Read AGENTS.md and resume from the latest note in .handoff/"
> - Before clearing or switching tools: `/handoff`
> - To see available resume points: `/handoff-list`

## What NOT to do

- Do NOT create heavy multi-file status protocols (global status doc + active-sessions doc + task board, etc.) — that's the exact overhead this replaces
- Do NOT make session-start reads mandatory across multiple files
- Do NOT write progress to an external tool (wiki, vault, doc) during the session — git commits are the source of truth
- Do NOT skip the passphrase — it's what makes resuming a specific thread reliable when parallel sessions exist
- Do NOT drop the repo name from the passphrase — it must lead with `{repo-name}: ` so that, across many projects, you can always tell which one a note belongs to

## Why `.handoff/` + `AGENTS.md` instead of a heavier protocol

- `.handoff/` is in the project root → any AI tool can read it, no external path to configure
- A wiki/vault/doc system living outside the repo is invisible to tools that don't know about it
- Codex, Gemini CLI, and other tools don't share Claude Code's config — `AGENTS.md` is the one file format most of them already read
- Plain markdown in the project root = universal compatibility, zero setup cost per tool

## The handoff note format

```markdown
# {date} — {task description}

Passphrase: "{repo-name}: {memorable phrase}"   # repo name FIRST — so you never forget which project this thread was

## What was done
- ...

## Current state
- Verified: ...
- Not verified: ...

## Running state
- Background processes: {shell IDs + kill command, or "none"}
- Dev servers/ports: {url + port, or "none"}
- Open worktrees/branches: {paths, or "none"}

## Next step
1. ...

## Files to read next
- ...
```

Keep it under 80 lines. One file per session. That's it.
