---
name: refresh
description: >
  Sync the active workspace repo to latest code, install deps if lockfiles changed,
  run migrations when needed, and restart its dev server. Use when the user says
  refresh, pull and run, sync and restart, rerun the app, reset dev environment,
  or invokes /refresh. Always targets the repo Cursor has open — never monjizeen
  or mora by default.
---

# Refresh

Sync **the repo that invoked this skill** to latest code, prune stale branches (QUICK mode), and restart its dev server.

**Not** `/refresh-mora` — that syncs org infra + all REGISTRY repos. This skill is per-app only.

## Target repo (mandatory)

Resolve once at the start and use for **every** command:

```bash
REPO_ROOT="$(git -C "${workspace}" rev-parse --show-toplevel 2>/dev/null)"
```

- `${workspace}` = Cursor's active workspace root (the project Omar has open).
- If `REPO_ROOT` is empty, stop — not inside a git repo.
- `cd "$REPO_ROOT"` before git, composer, npm, and artisan steps.
- **Never** assume `monjizeen/`, `mora/`, or any fixed path unless that repo is the active workspace.
- Report the repo name in the summary (basename of `REPO_ROOT`).

Detect mode:

```bash
if [ -f "$REPO_ROOT/.git" ]; then echo WORKTREE; else echo QUICK; fi
```

## When to use

- "refresh"
- "pull latest and rerun the app"
- "sync and restart"
- "rerun the app"
- "reset dev environment"
- `/refresh`

---

## Steps

### 1. Git sync

#### QUICK mode (`.git` is a directory)

Follow **every step** in [cleanup/SKILL.md](../cleanup/SKILL.md) **in `REPO_ROOT`**:

1. Check for uncommitted changes (warn, stash/discard/abort — never proceed silently)
2. `git checkout main`
3. `git pull origin main` (if pull fails: `git fetch --prune`, then retry)
4. `git fetch --prune`
5. Delete stale local branches (gone upstream, merged, or squash-merged)

Stop if the user aborts or the working tree cannot be made clean.

#### WORKTREE mode (`.git` is a file)

Do **not** checkout `main` — that breaks the worktree.

1. Check for uncommitted changes (same rules as cleanup)
2. Current branch: `git branch --show-current`
3. `git pull --rebase` (or `git pull` if no upstream — report and stop)
4. Skip branch pruning (other worktrees may use those branches)

Stop if the user aborts or the working tree cannot be made clean.

### 2. Post-pull setup

Run only when a pull actually brought new commits. If already up to date, skip to step 3 unless deps/migrations were never run.

Record pre-pull ref when a pull happened:

```bash
PREV_REF="$(git rev-parse HEAD@{1} 2>/dev/null)"   # after pull
CUR_REF="$(git rev-parse HEAD)"
```

#### 2a. Install dependencies (when lockfiles changed)

Only when `composer.lock` or `package-lock.json` exists under `REPO_ROOT`:

```bash
git diff "$PREV_REF" "$CUR_REF" --name-only -- composer.lock package-lock.json
```

If either file appears:

```bash
test -f composer.json && composer install --no-interaction
test -f package.json && npm install
```

#### 2b. Run database migrations (Laravel only)

Only when `REPO_ROOT/artisan` exists:

```bash
git diff "$PREV_REF" "$CUR_REF" --name-only -- database/migrations/
```

If any migration file appears:

```bash
php artisan migrate --no-interaction
```

Missing migrations cause runtime errors. Always migrate before restarting the dev server.

### 3. Stop running dev processes (this repo only)

Inspect the terminals folder for active dev commands **in `REPO_ROOT`**.

Prefer stopping processes tied to this repo before killing ports globally:

```bash
pkill -f "${REPO_ROOT}.*artisan queue:listen" 2>/dev/null || true
pkill -f "${REPO_ROOT}.*artisan pail" 2>/dev/null || true
pkill -f "${REPO_ROOT}.*artisan serve" 2>/dev/null || true
pkill -f "${REPO_ROOT}.*npm run dev" 2>/dev/null || true
pkill -f "concurrently.*${REPO_ROOT}" 2>/dev/null || true
```

If ports are still in use and this repo uses the default Laravel + Vite stack (`composer.json` has a `dev` script), free default ports (macOS/Linux):

```bash
for port in 8000 5173; do
  lsof -ti :"$port" | xargs kill 2>/dev/null || true
done
```

If a terminal still shows an active dev command for this repo, note it. Do not leave duplicate servers on the same ports.

### 4. Start the dev server

From `REPO_ROOT`, detect stack:

| Detect | Start command |
|--------|----------------|
| `composer.json` has `"dev"` script | `composer dev` |
| `artisan` exists, no `dev` script | `php artisan serve` (+ `npm run dev` if `package.json` exists) |
| `package.json` only (no `artisan`) | `npm run dev` |
| None of the above (e.g. `mora`, `shared-assets`) | Skip — report "no dev server for this repo" |

Run the start command in the **background** (`block_until_ms: 0`).

Typical Laravel `composer dev` (monjizeen, kawader, modarraj-backend, with-motion-backend):

| Process | Role |
|---------|------|
| `php artisan serve` | HTTP (http://127.0.0.1:8000) |
| `php artisan queue:listen` | Queue worker |
| `php artisan pail` | Log tail |
| `npm run dev` | Vite HMR |

Wait a few seconds, then confirm the server is up (terminal output or `lsof -i :8000` / `lsof -i :5173`).

### 5. Report to user

Summarize for **`REPO_ROOT`** (repo name, not a hardcoded product):

- QUICK or WORKTREE mode
- Branch synced (`main` or feature branch name)
- Branches deleted vs kept (QUICK only)
- Whether `composer install` / `npm install` ran
- Whether `php artisan migrate` ran
- Dev server URL if started (default **http://127.0.0.1:8000** for Laravel)
- Any blockers (dirty tree, failed pull, port still in use, no dev script)

---

## Rules

- **Always operate on the active workspace repo** — never refresh a different project unless Omar explicitly names one and you `cd` there first.
- **Never discard uncommitted changes** without explicit user consent.
- **Never force-push** or rewrite history during refresh.
- **QUICK:** never skip cleanup — pulling on a feature branch with stale locals is not a refresh.
- **WORKTREE:** never checkout `main` from the worktree.
- **Idempotent** — running `/refresh` twice should be safe (second run: no new pull, few or no branches to delete, restart dev server).
