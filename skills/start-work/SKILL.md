---
name: start-work
description: Begin a task — sync main (QUICK mode) or confirm branch (WORKTREE mode). Challenge scope before coding. Use when the user says "start work", "new task", "begin working on", or invokes /start-work.
---

# Start Work

Org-wide skill for monjizeen repos. Repo-local overrides win when present.

## Two modes only

| Mode | Detect | Where you work |
|------|--------|----------------|
| **QUICK** | `.git` is a directory (main working tree) | `main` directly |
| **WORKTREE** | `.git` is a file (linked worktree) | Feature branch only — never `main` |

```bash
if [ -f .git ]; then echo WORKTREE; else echo QUICK; fi
```

## When to use

- "start work on …"
- "new task: …"
- "begin working on …"
- Any time you are about to begin a new scoped task

**Check first:** If already mid-task on the correct branch (worktree) or on `main` with main synced (quick), skip redundant steps.

---

## QUICK mode (main)

Work directly on `main`. No branches. No PRs.

### Steps

1. Sync main:
   ```bash
   git checkout main
   git pull origin main
   ```
   If pull fails due to stale refs:
   ```bash
   git fetch --prune
   git checkout main
   git pull origin main
   ```

2. Challenge before executing (see below).

3. Confirm ready — on `main`, synced, ready to work.

### Rules

- Commit frequently during the task.
- Keep `main` stable and deployable — run checks before commits when the repo provides them.
- Push only when Omar says ship / push / backup.
- **Never** create branches or PRs in quick mode.

---

## WORKTREE mode (branches)

One branch per worktree. Never touch `main` from here.

### Steps

1. Confirm current branch is **not** `main`:
   ```bash
   git branch --show-current
   ```
   If on `main`, stop and flag — worktree must use a feature branch.

2. Sync the branch with its remote tracking branch if one exists:
   ```bash
   git pull --rebase 2>/dev/null || true
   ```

3. Challenge before executing (see below).

4. Confirm ready — branch name, not on `main`, ready to work.

### Branch naming (when creating a new worktree)

| Type | Prefix |
|------|--------|
| New feature | `feat/` |
| Bug fix | `fix/` |
| Refactor | `refactor/` |
| Maintenance / config / docs | `chore/` |

Short kebab-case description (2–4 words). Example: `feat/user-roles-management`.

### Rules

- Commit frequently during the task.
- **Never** modify `main` from a worktree.
- **Never** merge into `main` automatically — Omar reviews and merges manually.
- After Omar merges: delete the branch and close the worktree.
- Push only when Omar says ship / push / backup.
- **Never** create PRs automatically.

---

## Challenge before executing (both modes)

Before confirming ready, put on your **skeptical CTO + concerned CEO hat** and surface any of the following that apply:

| Category | What to surface |
|----------|----------------|
| **Clarifying questions** | Ambiguous requirements, missing acceptance criteria, undefined edge cases |
| **Business logic concerns** | Does this make sense from a product/user perspective? Revenue impact? User confusion risk? |
| **Technical conflicts** | Will this clash with existing code, patterns, or in-flight work? |
| **Better alternatives** | Is there a simpler, cheaper, or more maintainable way to achieve the same goal? |
| **Scope concerns** | Is this too big for one branch? Should it be split? Is scope creeping? |
| **Risk flags** | Breaking changes, data migrations, security implications, performance concerns |
| **Missing context** | Do you need to read specific files, check existing implementations, or understand domain terms first? |

**Format:** Short numbered list. Group by category. Ask questions if decisions are needed before proceeding.

**Rules:**
- Do NOT skip this step. Even "obvious" tasks get a 30-second sanity check.
- If genuinely nothing to flag (rare), say so explicitly: "No concerns — task is clear and well-scoped."
- If concerns exist, **wait for user response** before proceeding.
- Keep it concise — this is a gate, not a design doc.

For non-trivial work, draft a short implementation plan (files to touch, order of steps) and get approval before coding.

---

## Output (TLDR only)

After start-work steps: **give Omar TLDR only.**

| Include | Skip unless asked |
|---------|-------------------|
| Mode (QUICK / WORKTREE) | Full memory excerpts |
| Branch or `main` synced | Long plan prose |
| Ready yes/no | Design doc / essay |
| Blockers or 1-line flags | Repeated git command output |

Max ~5 bullets or 4 short lines.

---

## General rules (both modes)

- `main` must always stay stable and deployable.
- One branch = one logical change (worktree mode).
- **Ask for the task description** if unclear (needed for branch naming in worktree mode).
