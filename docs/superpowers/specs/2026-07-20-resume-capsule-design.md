# Resume Capsule: fast cross-session restart

## Status

Approved design direction; implementation has not started.

## Problem

The current handoff workflow treats a passphrase as a human-friendly lookup key. On the next session, the AI may still need to list notes, match a passphrase, read the selected note in full, and infer the next action. That discovery loop consumes tokens before useful work begins.

The desired workflow is to copy one restart prompt into an AI chat and begin work immediately. Terminal users should have a second, equivalent entry point. The existing handoff note remains the source of detailed context and the existing passphrase workflow remains available as a fallback.

## Goals

- Start the next AI session from an explicit, copy-ready prompt without searching `.handoff/`.
- Keep the initial restart context small enough to minimize input and read tokens.
- Include the exact handoff file path for detail lookup and auditability.
- Emit both a chat prompt and a terminal command after `/handoff` writes the note.
- Preserve the existing global `handoff` skill contract and old-note compatibility.
- Keep one handoff note per invocation; do not introduce a mutable `LATEST.md` pointer.

## Non-goals

- Automatically launching every supported AI tool from the terminal in v1.
- Rewriting or migrating existing handoff notes.
- Replacing `/handoff-list` or passphrases for users who prefer manual thread selection.
- Adding an external database, cloud store, or multi-file status protocol.

## Design

### 1. Resume Capsule

Every new handoff note starts with a fixed, compact block immediately after the title:

```markdown
## Resume Capsule

Project: cross-model-handoff
Handoff: .handoff/2026-07-20-installer-design.md
Passphrase: "cross-model-handoff: 再開プロンプトを設計する"
Goal: ハンドオフ再開時のトークン消費を減らす
State: Resume Capsule方式を設計中
Next: 2種類の再開出力形式を決める
Read first: skills/handoff/SKILL.md; README.ja.md
Running: none
```

The fields are intentionally fixed and short:

- `Project`: repository name derived from the project root.
- `Handoff`: project-relative path to this exact note.
- `Passphrase`: the existing `{repo-name}: {phrase}` format; this remains the canonical identifier.
- `Goal`: the outcome of the session.
- `State`: a compact summary of the verified and unresolved state. Detailed verified/not-verified information remains below.
- `Next`: one concrete, imperative next action.
- `Read first`: zero to three files needed before taking `Next`.
- `Running`: a compact running-state summary, or `none`.

The Capsule should normally stay below 120 words and ten lines including its heading. It must not contain secrets, long logs, or a full history. The existing detailed sections remain after it and continue to contain `What was done`, `Current state` (including verified and not verified items), `Running state` (including shell IDs, kill commands, servers, ports, and worktrees), `Next step`, and `Files to read next`.

The Capsule is the canonical location for the passphrase in new notes. This keeps the current `handoff-list` and SessionStart parsers working without duplicate metadata.

### 2. Chat restart prompt

After writing the note, `/handoff` prints a copy-ready chat block. It embeds the Capsule values so the next AI can start without reading the note first:

```text
次の作業を再開してください。

Project: cross-model-handoff
Handoff file: .handoff/2026-07-20-installer-design.md
Goal: ハンドオフ再開時のトークン消費を減らす
State: Resume Capsule方式を設計中
Next: 2種類の再開出力形式を決める
Read first:
- skills/handoff/SKILL.md
- README.ja.md
Running: none

上記のNextをすぐ実行してください。
.handoff内の別ファイルや別の合言葉は探さないでください。
詳細が必要な場合だけ、指定したHandoff fileを参照してください。
```

The prompt must explicitly prefer the named handoff file and must not trigger a broad `.handoff/` scan. The user can paste it into a new AI chat opened in the project. The prompt should remain under approximately 200 input tokens for a typical note.

The existing Japanese completion message required by the global skill remains unchanged and appears before these copy-ready blocks.

### 3. Terminal restart command

The second output is a copy-ready, tool-neutral command:

```bash
npx cross-model-handoff resume --file .handoff/2026-07-20-installer-design.md
```

The command reads only the explicitly named file, extracts its Resume Capsule, and writes the equivalent chat restart prompt to standard output. It does not search other handoff notes or launch an AI tool in v1. Tool-specific launching and clipboard support can be added later as adapters, for example an optional `--copy` mode, without changing the note format.

### 4. Existing workflow and compatibility

The feature is additive:

- The global `handoff` skill keeps its six required content areas, under-80-line limit, one-file-only rule, repo-prefixed passphrase, and Japanese completion message.
- The repository copy of `skills/handoff/SKILL.md` and the global copy must be updated together and remain identical.
- `handoff-list` remains the discovery fallback for lost prompts, parallel sessions, and manual thread selection.
- Legacy notes without a Capsule remain readable through their existing `Passphrase:` or `合言葉:` line. They are not rewritten automatically.
- `SessionStart` continues to show a short list of recent notes as a fallback and does not inject full note contents.
- `PreCompact` changes its instruction to require a Resume Capsule when it asks the model to create the safety-net note.
- `handoff-setup` updates the generated AGENTS/session instructions so a direct restart prompt takes precedence over note discovery and says to read only the named note when detail is needed.

No `LATEST.md`, symlink, external state file, or second handoff note is created.

### 5. Error handling

- If the named handoff file is missing, `resume` exits non-zero and reports the exact path. It does not scan `.handoff/` automatically.
- If the note has no Capsule, `resume` reports that it is a legacy note and falls back to the existing full-note/manual workflow.
- If required Capsule fields are missing, `resume` reports the missing fields and outputs the file path for manual inspection. It must not invent `Next`.
- If `npx` or the CLI is unavailable, the chat block printed by `/handoff` remains sufficient for restart.
- If `Next` is vague, the generated prompt tells the AI to read only `Read first` and then ask for clarification rather than broadening the search.
- Running-state details must remain explicit. Use `none` when nothing is running; never omit the section.

## Data flow

```text
/handoff
  -> write one note with Resume Capsule + detailed sections
  -> print required completion message
  -> print chat restart prompt from Capsule
  -> print terminal resume command with exact file path

new chat prompt
  -> use embedded Capsule
  -> read only Read first files
  -> execute Next
  -> read named handoff file only if detail is missing

terminal resume command
  -> read exactly --file
  -> parse Capsule
  -> print equivalent chat prompt
```

## Verification plan

The implementation should verify:

1. A generated note starts with a valid Capsule and still contains all six existing detailed sections.
2. The passphrase is repo-prefixed and is discoverable by `handoff-list` and SessionStart.
3. The generated chat block contains the exact handoff path, `Next`, `Read first`, and the no-search instruction.
4. `resume --file` reads only the named file and produces the same prompt content.
5. Missing, legacy, malformed, and vague-Capsule cases follow the defined fallback behavior.
6. The global and repository `handoff` skill files remain byte-for-byte identical after the update.
7. Existing untracked or unrelated files are not modified by the handoff operation.

## Implementation surface

The eventual implementation plan should cover:

- `/Users/takao/.codex/skills/handoff/SKILL.md`
- `skills/handoff/SKILL.md`
- `skills/handoff-setup/SKILL.md`
- `hooks/precompact-handoff-gate.sh`
- `README.md`, `README.ja.md`, and other localized README references
- The universal CLI/parser described by `npx cross-model-handoff resume --file ...`
- Tests or fixtures for Capsule parsing, prompt generation, and legacy fallback

This document defines behavior only. No implementation is included yet.
