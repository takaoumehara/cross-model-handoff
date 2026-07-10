---
name: handoff-list
description: List handoff notes in .handoff/ for this project so you can pick one to resume
---

Scan `.handoff/*.md` in the project root, most recent first (limit ~10). For each file, extract the passphrase line (match `Passphrase:` or the legacy label `合言葉:`) and the date/slug from the filename.

Print a numbered list like:
```
1. {date} — {slug} — "{passphrase}"
2. {date} — {slug} — "{passphrase}"
...
```

Then wait for the user to pick a number, a filename, or say the passphrase itself. Once they pick, Read that file in full before resuming work — do not assume the most recent note is the right one, parallel sessions on the same branch can exist.

If `.handoff/` doesn't exist or has no `.md` files, say so plainly and suggest `git log --oneline -10` instead.
