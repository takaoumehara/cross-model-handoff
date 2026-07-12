# Universal multi-tool installer — design

Status: approved for planning
Date: 2026-07-12

## Problem

`cross-model-handoff` currently has two install paths:

1. **Claude Code** — a real plugin, installed via `/plugin marketplace add` + `/plugin install`.
2. **Every other tool** (Codex CLI, Gemini CLI, Qwen Code CLI, Cline, Kimi Code CLI, or any other AGENTS.md-aware tool) — fully manual: paste `skills/handoff-setup/SKILL.md` into the agent's chat and ask it to set itself up.

Path 2 works but doesn't scale as the user's workflow spans more tools, and produces no native `/handoff`-style command in tools that support one. The user wants an `npx`-style installer (inspired by `npx bmad-method install`) that can configure any subset of their tools in one run, and — since their actual workflow is IDE-first (VS Code, Antigravity) with almost no manual terminal use — must also be callable *by* an already-running coding agent, not just by a human typing in a terminal.

## Goals

- One `npx cross-model-handoff install` command that scaffolds the universal layer (`AGENTS.md` + `.handoff/`) and, where a tool supports it, a native `/handoff`-equivalent command file.
- Works when a human runs it directly in a terminal (interactive wizard) **and** when an AI agent runs it on the human's behalf via its own shell tool (non-interactive, flag-driven).
- Auto-detects which tools are already in use on the machine/project and pre-selects them; user (or agent) can override.
- Safe to re-run: idempotent, never duplicates or clobbers content it doesn't own.
- Every install step ends with a verifiable pass/fail summary — "installed" must mean "confirmed working," not "files were written."
- v1 covers: Claude Code, Codex CLI, Gemini CLI, Qwen Code CLI, Cline, Kimi Code CLI (the six tools the user actually uses).

## Non-goals

- No change to the existing Claude Code plugin mechanism itself — the installer's Claude Code adapter just drives the existing `claude plugin` CLI, it doesn't reimplement plugin installation.
- No GUI/browser installer. Terminal (human or agent-driven) only.
- Not attempting to support all 60+ AGENTS.md-aware tools in v1 — the manual SKILL.md-paste path remains the fallback for anything not in the six.

## Naming decision (recorded, not re-litigated)

- The npm package / CLI invocation stays `cross-model-handoff` (`npx cross-model-handoff install`) — matches the existing plugin/repo name, npm name is available (confirmed unregistered as of 2026-07-12).
- Post-install runtime command name differs by tool, and this is inherent to each tool's own design, not a choice we control:
  - **Claude Code**: always `/cross-model-handoff:handoff` — plugin commands are structurally namespaced by Claude Code, with no unqualified fallback, confirmed against current docs.
  - **Codex / Gemini CLI / Qwen Code / Cline / Kimi**: just `/handoff` — these tools resolve custom commands by filename stem, no marketplace-style namespace exists.
- Skill/command internal names (`handoff`, `handoff-list`, `handoff-setup`) are kept as-is — user confirmed no existing conflict on their machine, and namespacing already isolates Claude Code's copy.

## Architecture

New `cli/` directory added to the existing repo (single package, not a separate repo):

```
cross-model-handoff/
├── cli/
│   ├── package.json          # name: "cross-model-handoff", bin: "cross-model-handoff"
│   ├── bin.js                 # entry point, arg parsing, dispatches to wizard or flag-driven run
│   └── src/
│       ├── wizard.js           # interactive prompts (tool checklist, confirm project dir)
│       ├── detect.js           # auto-detection (see below)
│       ├── scaffold-core.js    # writes AGENTS.md + .handoff/, managed-block aware
│       ├── verify.js           # post-install verification + summary report
│       └── adapters/
│           ├── claude-code.js
│           ├── codex.js
│           ├── gemini-cli.js
│           ├── qwen-code.js
│           ├── cline.js
│           └── kimi-code.js
├── skills/        # existing — canonical source content adapters translate from
├── hooks/         # existing, unchanged
└── .claude-plugin/  # existing, unchanged
```

Each adapter exports the same shape:

```js
{
  id: "codex",
  detect(),          // -> boolean, best-effort auto-detection
  install(projectRoot, opts), // -> writes/updates files or shells out; must be idempotent
  verify(projectRoot),        // -> boolean/details, confirms the install actually took
}
```

`scaffold-core.js` runs first and unconditionally for every invocation (all tools depend on `AGENTS.md` + `.handoff/` existing). Adapters run after, one per selected tool, independently — a failure in one adapter must not block the others or roll back the core scaffold.

## CLI UX

Two modes, both always available:

- **Interactive wizard** — `npx cross-model-handoff install` with no flags. Runs detection, shows a checkbox list of the six tools with detected ones pre-checked, confirms target project directory, runs selected adapters, prints a verification summary.
- **Non-interactive** — for an AI agent driving the installer via its own shell/bash tool (the user's primary real-world path, since they work IDE-first and rarely touch a terminal by hand):
  - `npx cross-model-handoff install --tools=claude-code,codex,gemini-cli --yes` — installs exactly the listed tools, no prompts.
  - `npx cross-model-handoff install --auto` — installs for every tool `detect()` finds, no prompts.

Exit code is non-zero if any requested adapter fails verification, so an agent invoking this can tell success from failure without parsing output.

## Detection (`detect.js`)

Best-effort signal per tool, OR'd together where more than one applies:

- **Claude Code**: `claude` binary on `PATH` (`which claude`).
- **Codex**: `codex` binary on `PATH`, or `~/.codex/` directory present.
- **Gemini CLI**: `gemini` binary on `PATH`, or `~/.gemini/` present.
- **Qwen Code**: `qwen` binary on `PATH`, or `~/.qwen/` present.
- **Kimi Code**: `kimi`/`kimi-code` binary on `PATH`, or `~/.kimi-code/` present.
- **Cline**: best-effort only — `code --list-extensions` (if the `code` CLI is on `PATH`) grepped for Cline's extension id. If that check isn't possible, Cline is never auto-checked and is left for manual selection in the wizard (never auto-selected in `--auto` mode, since there is no reliable signal).

Detection failures are non-fatal — worst case a tool isn't pre-checked and the user/agent selects it explicitly.

## Per-tool adapter behavior

Core scaffold (`AGENTS.md` + `.handoff/`) is shared and always runs first; this table covers each adapter's *additional* tool-specific step.

| Tool | Adapter action | Confidence |
|---|---|---|
| Claude Code | Shell out to `claude plugin marketplace add takaoumehara/cross-model-handoff` (idempotent — skip if already present) then `claude plugin install cross-model-handoff@cross-model-handoff`. Reuses the existing, already-versioned plugin mechanism rather than duplicating it. | Confirmed (this is exactly what was run manually during design) |
| Gemini CLI | Write `.gemini/commands/handoff.toml` (project-scoped) with a `prompt` field carrying the handoff-note instructions. Additionally, since Gemini CLI does not read `AGENTS.md` by default, merge `"AGENTS.md"` into `context.fileName` in the project's `.gemini/settings.json` (create if absent, managed-block-style merge if present). | Confirmed via current docs |
| Qwen Code CLI | Write `.qwen/commands/handoff.md` (Markdown + YAML frontmatter — the current format per Qwen's docs; TOML is legacy). Same `context.fileName` merge as Gemini CLI, but in `.qwen/settings.json`. | Confirmed via current docs |
| Cline | Write `.clinerules/workflows/handoff.md` (Cline's Workflows feature — plain Markdown, invoked as `/handoff.md`, no build step). Do **not** rely on Cline's `AGENTS.md` auto-read (reports of this are inconsistent/in flux) — the workflow file's own content carries the full instructions rather than assuming it'll be composed with AGENTS.md context automatically. | Workflows path confirmed; AGENTS.md auto-load unconfirmed, adapter is written not to depend on it |
| Codex CLI | Write `~/.codex/prompts/handoff.md` (user-level only — Codex has no project-level custom-prompt directory). **Re-verify at implementation time**: current information suggests this custom-prompts mechanism may be mid-deprecation in favor of a "skills" system; adapter must be implemented against whatever is current at build time, not this design doc. | Needs re-verification before implementation |
| Kimi Code CLI | Write `~/.kimi-code/skills/handoff/SKILL.md`, following Kimi's Agent Skills format (YAML frontmatter: `name`, `description`, `type: prompt`). This format is close enough to Claude Code's own skill format that content can likely be adapted directly from `skills/handoff/SKILL.md`. | Medium confidence — newer/fast-moving tool, re-verify at implementation time |

All adapter-written files use an HTML comment marker (`<!-- cross-model-handoff:managed -->` / TOML equivalent) wrapping the block they own, so re-running the installer updates only that block and never duplicates or destroys user content placed outside it. The same marker convention already used informally in `handoff-setup`'s `CLAUDE.md` session-rules block extends to every file this CLI touches.

## Verification & summary

After all selected adapters run, `verify.js` re-checks each one:

- Claude Code: `claude plugin list` output contains `cross-model-handoff@cross-model-handoff`.
- File-based adapters: target file exists and contains the managed-block marker.

Final output is a per-tool ✅/❌ table, e.g.:

```
cross-model-handoff install — summary
  ✅ Claude Code   /cross-model-handoff:handoff
  ✅ Gemini CLI    /handoff
  ❌ Codex         prompt file written, but "codex" not found on PATH to verify — check manually
  ⏭  Cline         skipped (not selected)
```

Non-zero exit code if any selected tool shows ❌.

## Open questions to resolve during implementation (not blocking spec approval)

1. Confirm Codex CLI's current custom-prompt mechanism at build time (deprecation status).
2. Confirm Kimi Code CLI's exact Agent Skills schema at build time (product is new/fast-moving).
3. Confirm whether Cline's `AGENTS.md` auto-load has stabilized; if so, the Cline workflow file could be simplified to a short pointer instead of embedding full instructions.
4. Decide packaging details (TypeScript vs plain JS, which prompt-library for the interactive wizard) — implementation-plan level, not a design-level decision.

## Out of scope for this design

- Publishing/CI mechanics (npm publish workflow, version bump automation) — follow-up.
- A `status` subcommand (`npx cross-model-handoff status` showing what's configured in a project) — nice-to-have, not required for v1.
