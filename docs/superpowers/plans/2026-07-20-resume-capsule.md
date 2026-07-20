# Resume Capsule Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update the installed global `handoff` skill and repository copy so new notes begin with a compact Resume Capsule and emit chat and terminal restart outputs.

**Architecture:** Keep one Markdown note as the source of truth. Add a fixed Capsule at the top, preserve the existing detailed sections, and update the PreCompact safety-net prompt. The future CLI is documented but not implemented in this change; the chat block remains the usable fallback.

**Tech Stack:** Markdown instructions, POSIX shell, Git verification.

## Global Constraints

- Capsule: at most ten lines including its heading and normally under 120 words.
- Complete note: under 80 lines.
- Global and repository `handoff` skill files must be byte-for-byte identical.
- Preserve the repo-prefixed passphrase and all existing detailed content areas.
- Write one handoff file only; do not create `LATEST.md` or external state.
- Do not claim the future `npx cross-model-handoff resume` command is available until a CLI exists.
- Leave the user's unrelated untracked plan contents untouched.

---

### Task 1: Synchronize the handoff skill instructions

**Files:**
- Modify: `/Users/takao/.codex/skills/handoff/SKILL.md`
- Modify: `skills/handoff/SKILL.md`
- Test: `cmp` and `rg` checks below

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-07-20-resume-capsule-design.md`
- Produces: identical instructions for writing the Capsule and printing both restart outputs

- [ ] **Step 1: Confirm the current behavior is absent**

Run:

```bash
cmp -s /Users/takao/.codex/skills/handoff/SKILL.md skills/handoff/SKILL.md
! rg -q "Resume Capsule" /Users/takao/.codex/skills/handoff/SKILL.md
```

Expected: `cmp` succeeds and the second command succeeds because the feature is not present.

- [ ] **Step 2: Update both skill files together**

Add the approved contract: a `## Resume Capsule` immediately after the title with `Project`, `Handoff`, repo-prefixed `Passphrase`, `Goal`, `State`, `Next`, `Read first`, and `Running`; retain the existing detailed sections and one-file/80-line rules; retain the exact Japanese completion message; then print a chat prompt embedding Capsule values and a terminal command:

```bash
npx cross-model-handoff resume --file .handoff/{YYYY-MM-DD}-{task-slug}.md
```

The instructions must say that the terminal command is a future CLI entry point, that the chat prompt is the fallback when the CLI is unavailable, and that the agent must not search other `.handoff` files or claim the command ran.

- [ ] **Step 3: Verify synchronization**

```bash
cmp /Users/takao/.codex/skills/handoff/SKILL.md skills/handoff/SKILL.md
rg -n "Resume Capsule|Terminal restart command|Do not claim" /Users/takao/.codex/skills/handoff/SKILL.md
```

Expected: `cmp` exits 0 and all three phrases are present.

- [ ] **Step 4: Commit only the repository copy**

```bash
git add skills/handoff/SKILL.md
git commit -m "feat: add resume capsule handoff instructions"
```

The global file is outside the repository and must not be staged.

### Task 2: Update the PreCompact safety-net prompt

**Files:**
- Modify: `hooks/precompact-handoff-gate.sh`
- Test: `bash -n` and `rg`

**Interfaces:**
- Consumes: the Capsule contract from Task 1
- Produces: a PreCompact reason that requests the Capsule and existing detailed state sections

- [ ] **Step 1: Confirm the hook does not request the Capsule**

```bash
! rg -q "Resume Capsule" hooks/precompact-handoff-gate.sh
```

- [ ] **Step 2: Replace only the human-readable reason text**

Keep the existing JSON decision, session marker, project directory resolution, and one-note behavior. Add the fixed Capsule fields, existing detailed sections, `Running state`, and one-file-only rule to the reason. The hook must continue asking the model to write the note; it must not write the note itself.

- [ ] **Step 3: Verify and commit**

```bash
bash -n hooks/precompact-handoff-gate.sh
rg -n "Resume Capsule|Passphrase|Running state|Do NOT update any other files" hooks/precompact-handoff-gate.sh
git add hooks/precompact-handoff-gate.sh
git commit -m "feat: request resume capsule before compaction"
```

Expected: syntax exits 0 and all required phrases are present.

### Task 3: Verify and push the intended commits

**Files:**
- Verify: `docs/superpowers/specs/2026-07-20-resume-capsule-design.md`
- Verify: `skills/handoff/SKILL.md`
- Verify: `hooks/precompact-handoff-gate.sh`

- [ ] **Step 1: Run fresh checks**

```bash
git status --short --branch
git diff origin/main...HEAD --stat
git diff origin/main...HEAD --check
cmp /Users/takao/.codex/skills/handoff/SKILL.md skills/handoff/SKILL.md
bash -n hooks/precompact-handoff-gate.sh
```

Expected: only intended committed files are in the diff; the pre-existing unrelated plan directory remains untracked; every check exits 0.

- [ ] **Step 2: Push the confirmed local commits**

```bash
git push origin main
```

- [ ] **Step 3: Verify the remote tip**

```bash
git ls-remote origin HEAD refs/heads/main
git status --short --branch
```

Expected: remote `main` matches local `HEAD`, and no unrelated file was staged or deleted.
