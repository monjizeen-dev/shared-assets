---
name: finish-work
description: >
  Wrap up a task — checks + commit when done; playground (mnjz.in) also pushes.
  Use when the user says finish work, ship it, wrap up, done with this, or invokes /finish-work.
---

# Finish Work

Org-wide skill for monjizeen repos. Repo-local overrides win when present.

## Two modes only

| Mode | Detect | When task done | When Omar says ship |
|------|--------|----------------|---------------------|
| **QUICK** | `.git` is a directory | Checks → commit on `main` | Push `main` |
| **WORKTREE** | `.git` is a file | Checks → commit on branch | Push branch → create PR; Omar merges manually |

```bash
if [ -f .git ]; then echo WORKTREE; else echo QUICK; fi
```

## Commit vs push (org default)

| Action | When |
|--------|------|
| **Commit** | Always when the asked coding task is done (checks green, no conflicts). Also on stop-hook dirty follow-up. Do **not** wait for Omar to say "commit". |
| **Push (playground)** | Repo deploys only to `{project}.mnjz.in` (no customer production) → **push when the task is done**. Don't wait for "ship". That's how the test site updates. |
| **Push (live)** | Customer / custom-domain apps → only when Omar says **ship** / **ship it** / **push** / **backup**. |

Detect playground: agent `MEMORY.md` says deploy mode playground, or the app URL is `*.mnjz.in` with no separate production.

Opt out: "don't commit", "WIP only", discuss/plan-only turns (no repo edits).

## When to invoke

- After completing a coding task that changed the repo → **auto commit**; **also push** if playground
- The user says "finish work", "wrap up", "done with this" → same
- The user says "ship" / "ship it" / "push" / "backup" → push (WORKTREE: then PR if needed)
- **Stop hook fired** with uncommitted changes — commit now; **also push** if playground; else do not push unless Omar said ship

**QUICK:** Never create PRs. **WORKTREE:** Create PR after ship push when ahead of `main` with no open PR. **Never** auto-merge into `main`.

---

## During work (commit frequently)

After meaningful edits, commit without waiting for task end:

- Stage only files you actually changed (never `git add -A` or `git add .`):
  ```bash
  git add path/to/file1 path/to/file2
  ```
- Commit with a short imperative message explaining *why*:
  ```bash
  git commit -m "message here"
  ```
- One commit per logical unit. Never commit `.env`, credentials, or secrets.
- **Do not push** mid-task unless Omar asks for backup / ship.

---

## Task complete (commit path)

Run when the task is done or Omar says to wrap up.

### 1. Run all required tests

Run only what the repo provides:

```bash
# PHP / Laravel repos
test -f composer.json && composer check

# Frontend / Node repos
test -f package.json && npm run lint
```

- `composer check` (when present): formatting + static analysis + tests.
- `npm run lint` (when present): frontend lint.

**If tests fail:** Fix the issues. Re-run until all pass. Do not proceed until green.

### 2. Commit remaining changes

Run `git status`. If there are uncommitted changes, commit using the rules above.

### 3. Push

**Do this step when:** playground (`*.mnjz.in`, no customer production) **or** Omar said ship / ship it / push / backup.

Skip for live/customer apps unless Omar said ship.

```bash
git push -u origin HEAD
```

**QUICK + playground:** push `main` (test site updates).
**QUICK + live, no ship:** report commits are local.
**QUICK + live, ship:** push `main`.
**WORKTREE:** without ship → local on the branch. With ship → push, then open PR.

### 4. Create a Pull Request (WORKTREE + ship only)

Skip in QUICK mode. Skip if Omar has not said ship.

```bash
gh pr create --title "Short title under 70 chars" --body "$(cat <<'EOF'
## Summary
- bullet point describing what changed and why

## Test plan
- [ ] Tests pass (composer check when present)
- [ ] Lint passes (npm run lint when present)
- [ ] Additional manual verification if applicable
EOF
)"
```

If an open PR already exists for this branch, skip creation and report the existing URL.

**Do not** run `gh pr merge --auto` from a worktree. Omar merges manually or says "merge it".

### 5. Report

**QUICK + playground:** Task done. Pushed to `main`. Test site (`*.mnjz.in`) should update.

**QUICK + live (no ship):** Task done. Commits on `main` (local). Say **ship** to push.

**QUICK + live (ship):** Task done. Commits on `main`. Pushed.

**WORKTREE (no ship):** Task done. Commits on `{branch}` (local). Say **ship** to push + open PR.

**WORKTREE (ship):** PR created: {url}. Omar merges manually when ready.

---

## Rules

- **Never force-push.** If conflict, rebase non-interactively or ask Omar.
- **Never amend commits** unless Omar explicitly requests it and the commit was not pushed.
- **Never skip hooks** (`--no-verify`). Fix the root cause.
- **Stage files explicitly** — never `git add -A` or `git add .`.
- **Playground (`*.mnjz.in`):** task done → commit + push. **Live / customer sites:** push only on ship.
- **Never auto-merge** into `main`.
- **`main` must always stay stable and deployable.**
