---
name: finish-work
description: >
  Wrap up a task — checks + commit + push when done. Ship = production deploy only.
  Use when the user says finish work, ship it, wrap up, done with this, or invokes /finish-work.
---

# Finish Work

Org-wide skill for monjizeen repos. Repo-local overrides win when present.

## Cursor chat mode (hard skip)

Finish-work runs **only in Agent mode**.

Skip entirely in **Ask**, **Plan**, and **Debug** (and Cmd+K / Edit): no commit, no push, no PR, no stop-hook follow-up. If a stop-hook message arrives in those modes, ignore it.

Agent mode: rules below.

## Two modes only

| Mode | Detect | When task done | When Omar says ship |
|------|--------|----------------|---------------------|
| **QUICK** | `.git` is a directory | Checks → commit + **push** `main` (staging / playground) | Production deploy only |
| **WORKTREE** | `.git` is a file | Checks → commit on branch | Push branch → create PR; Omar merges manually |

```bash
if [ -f .git ]; then echo WORKTREE; else echo QUICK; fi
```

## Commit vs push (org default)

| Action | When |
|--------|------|
| **Commit** | Always when the asked coding task is done (checks green, no conflicts). Also on stop-hook dirty follow-up. Do **not** wait for Omar to say "commit". |
| **Push** | Task done → **push** (QUICK `main`). Updates playground URL or live **staging**. Do not wait for "ship". |
| **Production (ship)** | Live customer site (`app.{domain}`) → only when Omar says **ship** / **ship it**. Trigger the production deploy job. Never auto-deploy production on push. |

Push on `main` deploys **staging** (or the playground URL). Production is a separate manual job. This org rule wins over generic “don't push” notes.

Opt out: "don't commit", "WIP only", "don't push", discuss/plan-only turns (no repo edits). **Ask / Plan / Debug:** never finish-work.

## When to invoke

- After completing a coding task that changed the repo → **commit + push**. Production still waits for ship.
- The user says "finish work", "wrap up", "done with this" → same
- The user says "ship" / "ship it" → production deploy (live apps). "push" / "backup" → git push if not already pushed. WORKTREE ship: push + PR.
- **Stop hook fired** with uncommitted changes — commit now, then push (QUICK). Do not deploy production. **Skip this if not in Agent mode.**

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

**Do this step when the task is done** (QUICK). Do not wait for "ship".

```bash
git push -u origin HEAD
```

**QUICK:** push `main` — playground URL or live **staging** updates. Production does **not** auto-deploy.
**WORKTREE:** without ship → local on the branch. With ship → push, then open PR.

If a repo's CI auto-deploys **production** on push to `main` (should not), stop and flag — do not push.

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

**QUICK (task done):** Task done. Pushed to `main`. Staging / playground should update. Say **ship** to put it on the live customer site.

**QUICK (ship):** Production deploy started. Live site should update when the job finishes.

**WORKTREE (no ship):** Task done. Commits on `{branch}` (local). Say **ship** to push + open PR.

**WORKTREE (ship):** PR created: {url}. Omar merges manually when ready.

### 6. Production deploy (ship only)

Live apps only, when Omar said **ship** / **ship it**:

```bash
gh workflow run ci.yml --ref main -f deploy_target=production
```

Skip if the repo has no production job (playground). Never run this on task-done push.

---

## Rules

- **Never force-push.** If conflict, rebase non-interactively or ask Omar.
- **Never amend commits** unless Omar explicitly requests it and the commit was not pushed.
- **Never skip hooks** (`--no-verify`). Fix the root cause.
- **Stage files explicitly** — never `git add -A` or `git add .`.
- **Push on task done** (QUICK `main`) — staging / playground. **Ship** = production deploy only. Never auto-deploy production.
- **Never auto-merge** into `main`.
- **`main` must always stay stable and deployable.**
