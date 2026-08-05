---
name: new-project
description: >
  Unified new monjizeen product setup — GitHub repo, scaffold, MORA registry,
  Google OAuth, DNS, VPS deploy. Same flow on Cursor (Mac) and Telegram (VPS).
  Use when user says /new-project, new project, init project, set up project,
  or project initiation. Alias /init-project.
disable-model-invocation: true
---

# New Project

**One command:** `/new-project` — Cursor on Mac **or** Telegram on VPS. Same gates, same checklist.

Alias: `/init-project` (legacy name — identical flow).

Read [reference.md](../init-project/reference.md) for stack routing, CI, nginx, OAuth, agent stubs.

---

## Platform

Detect before Gate 0:

| Signal | Platform | CWD for commands |
|--------|----------|------------------|
| Cursor, `~/.cursor/mono-root` exists | **cursor** | `{MONO_ROOT}/mora` or `{MONO_ROOT}/{PROJECT}` |
| Telegram bot, `MORA_MONO_ROOT=/srv/projects` | **telegram** | `{MONO_ROOT}/mora` |

**Resolve `MONO_ROOT`:**

```bash
MONO_ROOT="$(cat ~/.cursor/mono-root 2>/dev/null | head -1)"
MONO_ROOT="${MONO_ROOT:-${MORA_MONO_ROOT:-$HOME/Documents/work/monjizeen}}"
SHARED_ASSETS="${MONO_ROOT}/shared-assets"
MORA="${MONO_ROOT}/mora"
```

| Gate | Cursor (Mac) | Telegram (VPS) |
|------|--------------|----------------|
| 0 Bootstrap | `bootstrap-mac.sh` | `/sync all` + verify mora/shared-assets on disk |
| 1 Identity | Ask Omar (`AskQuestion` in Cursor) | Ask in chat — one question at a time |
| 2 GitHub | `gh repo create` on Mac | Same if `gh auth` on VPS; else tell Omar to auth or run on Mac |
| 3 Scaffold | `scaffold-web.sh` / `scaffold-expo.sh` on Mac | Prefer Mac; VPS scaffold only if Omar confirms |
| 4 MORA registry | Edit mora, sync-registry | Same — mora clone on VPS |
| 5 OAuth | **Manual** — pause for Omar | Collect creds via Telegram when ready |
| 6 Secrets | Write `~/.cursor/secrets/{project}.env` on Mac | **Mac required** for local secrets; VPS copies come in Gate 7 |
| 7 VPS DNS/nginx | `gate7.sh` from **Mac** (SSH → VPS) | Cannot run from VPS alone — Omar runs Gate 7 on Mac or says `skip vps` |
| 8–9 CI + verify | Mac or VPS with git push | Same |

**Telegram rules:** Never ask Omar to SSH manually. Run commands yourself on VPS. For Mac-only gates, state clearly what Omar must do on Mac or paste into Telegram.

**Work step by step.** At each **GATE**, collect required input, then continue. Never skip a gate. Never print secrets.

---

## Deploy modes (locked 2026-07-20)

Two kinds of web projects. Never mix “live on mnjz.in” and “live on custom domain” for the same app.

| Mode | When | Public URL(s) | Push `main` |
|------|------|---------------|-------------|
| **playground** | No custom domain in Cloudflare yet | `{project}.mnjz.in` only | Deploys there (no separate production) |
| **live** | Domain already in Cloudflare | Staging: `staging.{domain}` · Prod: `app.{domain}` | Staging auto; production = manual only |

**Examples**

| Project | Mode | Staging | Production |
|---------|------|---------|------------|
| hadeed | playground | `hadeed.mnjz.in` | — (same URL) |
| monjizeen | live | `staging.monjizeen.com` | `app.monjizeen.com` |
| modarraj | live | `staging.modarraj.com` | `app.modarraj.com` |

**Rules**

- Playground: one VPS tree (`…/staging`), one OAuth client, one DNS record on `mnjz.in`.
- Live: two VPS trees (`staging` + `production`), two OAuth clients, DNS on the **project’s domain zone** (not mnjz.in). Apex `{domain}` → redirect to `app.{domain}` (optional, later).
- Upgrade playground → live: use `/migrate-project` (when skill exists) — do not leave both mnjz live and domain live.

---

## Constants

| Key | Value |
|-----|-------|
| GitHub org | `monjizeen` |
| Playground FQDN | `{project}.mnjz.in` |
| Live staging FQDN | `staging.{domain}` |
| Live production FQDN | `app.{domain}` |
| VPS paths | Playground: `/srv/projects/{project}/staging` only · Live: `…/staging` + `…/production` |
| Org secrets file | `~/.cursor/secrets/monjizeen.env` |
| Staging/local secrets | `~/.cursor/secrets/{project}.env` |
| Production secrets | `~/.cursor/secrets/{project}-production.env` (live only) |
| Web scaffold | `{SHARED_ASSETS}/templates/web-app` |
| Mobile scaffold | `{SHARED_ASSETS}/scripts/init-project/scaffold-expo.sh` |
| Init scripts | `{SHARED_ASSETS}/scripts/init-project/` |

**Do not scaffold from `kawader`.**

---

## Progress checklist

Copy and update after each gate:

```
New project: {project} ({PROJECT_TYPE}, {DEPLOY_MODE})
- [ ] Gate 0 — Prerequisites
- [ ] Gate 1 — Project identity, stack, theme, deploy mode (web)
- [ ] Gate 2 — GitHub repo
- [ ] Gate 3 — Scaffold, mock data, tweakcn theme (web), first push
- [ ] Gate 4 — MORA registry + agent
- [ ] Gate 5 — Google OAuth (manual, web only)
- [ ] Gate 6 — Secrets on disk (web only)
- [ ] Gate 7 — VPS: DNS + nginx + deploy (web only, optional)
- [ ] Gate 8 — CI workflow
- [ ] Gate 9 — Verify & handoff
```

---

## Gate 0 — Bootstrap

### Cursor (Mac)

```bash
"${SHARED_ASSETS}/scripts/init-project/bootstrap-mac.sh"
```

Also valid: `/run-mora` then continue here.

### Telegram (VPS)

Pull latest hub repos:

```bash
cd "${MORA}" && git pull --ff-only
cd "${SHARED_ASSETS}" && git pull --ff-only
```

Verify org secrets on **Mac** exist before Gate 7 (Telegram can remind Omar).

Exit bootstrap **0** → Gate 1. Exit **1** → fix `need` items, re-run Gate 0.

---

## Gate 1 — Project identity & stack

**Ask Omar** (required), one at a time:

1. **Project name** — lowercase kebab-case (e.g. `my-app`). Drives repo, paths, playground subdomain.
2. **One-line purpose** — for MORA `REGISTRY.yaml`.
3. **Project type** — `content` | `web-app` | `native-mobile` (see [reference.md — Stack routing](../init-project/reference.md#stack-routing)).
4. **Deploy mode** (web only) — **playground** or **live**:
   - Playground = no custom domain yet → `{project}.mnjz.in` only.
   - Live = domain already in Cloudflare → ask for **base domain** (e.g. `monjizeen.com`).
5. If **live**: confirm Cloudflare zone exists for that domain (API check). Set:
   - `STAGING_FQDN=staging.{domain}`
   - `PRODUCTION_FQDN=app.{domain}`
6. If **playground**: set `STAGING_FQDN={project}.mnjz.in`, `PRODUCTION_FQDN=` (empty).
7. **Auth model** (web only) — `open` or `closed`.
8. **Design system** (web) — shadcn-vue + Lucide. Default yes.
9. **Theme** (web) — tweakcn URL or default `zinc`.
10. **Run VPS setup now?** (web only) — default `yes` on Mac if SSH ok; `later` skips Gate 7.

Validate name: `^[a-z][a-z0-9-]*[a-z0-9]$`, length 2–40, not reserved (`mora`, `shared-assets`, `kawader`).

Set: `PROJECT`, `PROJECT_TYPE`, `DEPLOY_MODE`, `DOMAIN` (live only), `STACK`, `STAGING_FQDN`, `PRODUCTION_FQDN`, `REPO`, `WORKSPACE="${MONO_ROOT}/${PROJECT}"`, theme vars.

Confirm summary before Gate 2.

---

## Gate 2 — GitHub repo

```bash
cd "${MONO_ROOT}"
gh repo create "monjizeen/${PROJECT}" --private --description "{purpose}" --confirm
```

If exists: `gh repo view monjizeen/${PROJECT}` and continue.

---

## Gate 3 — Scaffold, mock data & first push

**Hard rule:** Never ship an empty shell. After scaffold, before first push, the app must show **purpose-shaped mock data** from Gate 1 so Omar can click around on first login / first open. Blank “Replace this shell” dashboard = Gate 3 incomplete.

**Hard rule — design taste:** Mock UI must look **intentional**, not a text dump in default cards. First glance after login should feel designed (hierarchy, spacing, type, calm color). Slapdash label stacks = Gate 3 incomplete.

### Web

```bash
"${SHARED_ASSETS}/scripts/init-project/scaffold-web.sh" "${PROJECT}" "${MONO_ROOT}" "${AUTH_MODEL}"
cd "${WORKSPACE}"
git init && git branch -M main
```

Closed auth apps should redirect guests from `/` to `/login`; open apps keep the public home page. Customize README, `docs/ARCHITECTURE.md`. Apply tweakcn theme if not zinc (see init-project Gate 3).

#### Mock data (required — every web project)

From Gate 1 **one-line purpose**, add a thin demo slice (not the full product):

1. **Domain leftovers** — strip kawader/talent-directory leftovers that confuse the new product (unused Feature tests, dead requests/jobs that 404). Keep OAuth shell.
2. **Minimal models + migration(s)** for the core nouns in the purpose (e.g. tasks / files / metrics — whatever the purpose implies).
3. **Seeder** — realistic fake rows (enough to fill a list + detail / summary). Run `php artisan migrate:fresh --seed` locally and confirm dashboard is not empty.
4. **Dashboard (and any primary list screens)** — render seeded data. Mark UI as demo/mock if helpful. No empty placeholder copy.
5. **Tests** — at least one feature test that seeded/list page returns 200 for an authenticated user (or open-home equivalent).

Do **not** wait for a later feature task. Mock data is part of Gate 3, committed in the initial push.

#### Design quality (required — every web project)

Gate 3 UI is a **product preview**, not a scaffold dump. Meet all of these before first push:

1. **Hierarchy** — one clear page title, supporting line, primary content zone. Numbers and lists must not compete equally.
2. **Spacing rhythm** — consistent vertical rhythm; generous breathing room; no cramped stacked text rows.
3. **Typography** — load a purposeful font pair (not default Inter / Roboto / Arial / system-only). Use size/weight to separate title vs meta vs body.
4. **Atmosphere** — subtle background treatment (soft gradient or light pattern) — not a flat white void. Stay on brand tokens; avoid purple-on-white AI defaults, glow, and pill spam.
5. **Composition** — prefer sections + rows over a grid of identical cards. Cards only when they wrap a real interaction. Status/priority as quiet badges, not uppercase noise.
6. **Enjaz first** — use `@enjaz/design-system` primitives/patterns and Lucide only. Follow `enjaz/.../docs/NEW-PAGE.md` + gallery https://enjaz.mnjz.in. Record pattern slug in `BRIEF.md`.
7. **Taste check** — if Omar would say “looks like text slapped together,” redesign before push. When visual direction is unclear or Omar wants a redesign, route **frontend studio** (Lane B/C suggest) instead of shipping a bland shell.

#### App shell nav (required — every web project)

Wire `AppLayout` (and share `app.name` from `config('app.name')` via Inertia) before first push:

| State | Logo click | Header actions |
|-------|------------|----------------|
| Logged **out** | Home (`/`) — or login if closed-auth guest already redirected | **Theme toggle** + **Login** (no Dashboard link) |
| Logged **in** | **Dashboard** (`/dashboard`) | **Theme toggle** + **Sign out** only — **no** Dashboard nav link |

Also:

1. Display name = **project name** (`APP_NAME` / `config('app.name')`) everywhere — never the word `App` as fallback.
2. Closed auth: guests hitting `/` → login; authenticated users hitting `/` → dashboard.
3. Update template `AppLayout` + `HandleInertiaRequests` + login title to match so future scaffolds inherit this.

#### Light / dark mode (required — every web project)

Every web scaffold must ship a **working light/dark toggle** before first push. Not optional.

1. **Toggle in chrome** — sun/moon control in `AppLayout` header (logged in **and** out). Also on standalone auth screens (e.g. `LoginPage`) that skip `AppLayout`.
2. **Persist** — save preference (`light` / `dark` / `system`) in `localStorage`; apply `.dark` on `<html>`.
3. **Init early** — call `theme.init()` on app boot; add a tiny inline script in `app.blade.php` so the first paint matches the saved preference (no flash).
4. **Prefer Enjaz** — when `@enjaz/design-system` is wired, use its `ThemeToggle` + `store/theme.js`. Otherwise keep the template-local twin (`resources/js/components/ThemeToggle.vue` + `resources/js/store/theme.js`) shipped by `templates/web-app`.
5. **Tokens** — UI must look correct in both modes via `app-theme.css` (`:root` + `.dark`). Blank or broken dark = Gate 3 incomplete.

### Expo

```bash
"${SHARED_ASSETS}/scripts/init-project/scaffold-expo.sh" "${PROJECT}"
cd "${WORKSPACE}"
git init && git branch -M main
```

Same rules: purpose-shaped mock/fixture data **and** intentional layout/type/spacing — not blank or slapdash starter screens.

### Initial commit (both)

```bash
find . \( -name '.DS_Store' -o -name '._*' \) -delete 2>/dev/null || true
git add -A
git commit -m "chore: initial scaffold for ${PROJECT}"
git remote add origin "git@github.com:monjizeen/${PROJECT}.git" 2>/dev/null || true
git push -u origin main
```

---

## Gate 4 — MORA registry + agent

1. Edit `{MORA}/REGISTRY.yaml` — add repo + purpose. Prefer `deploy_mode: playground|live` when adding fields later.
2. Create `{MORA}/domains/monjizeen/agents/{PROJECT}/SKILL.md` and `MEMORY.md` ([agent stub](../init-project/reference.md#agent-stub)).
3. `python3 "${MORA}/scripts/sync-registry.py"`
4. Commit mora when Omar asks.

---

## Gate 5 — Google OAuth (manual — web only)

**Skip for `native-mobile`** unless also standing up web API.

**Pause until Omar confirms OAuth client ready.**

| Mode | Callbacks to show |
|------|-------------------|
| playground | `https://{project}.mnjz.in/auth/google/callback` + local `http://127.0.0.1:8000/auth/google/callback` |
| live | Staging client: `https://staging.{domain}/auth/google/callback` + local · Production client: `https://app.{domain}/auth/google/callback` |

See [reference.md — Google links](../init-project/reference.md#google-links-quick-reference).

---

## Gate 6 — Secrets on disk (web only)

| Mode | Files |
|------|-------|
| playground | `~/.cursor/secrets/{PROJECT}.env` only |
| live | `{PROJECT}.env` + `{PROJECT}-production.env` |

Update local `.env`. Never commit secrets.

If Gate 1 VPS = `later`, skip Gate 7.

---

## Gate 7 — VPS (web only, from Mac)

```bash
set -a && source ~/.cursor/secrets/monjizeen.env && set +a
# playground
"${SHARED_ASSETS}/scripts/init-project/gate7.sh" "${PROJECT}" playground
# live
"${SHARED_ASSETS}/scripts/init-project/gate7.sh" "${PROJECT}" live "${DOMAIN}"
```

| Mode | Creates |
|------|---------|
| playground | DNS `{project}.mnjz.in`, nginx → `…/staging`, one deploy tree |
| live | DNS `staging.{domain}` + `app.{domain}` on that domain’s Cloudflare zone, nginx → staging + production |

**Expo:** skip — document EAS path in handoff.

---

## Gate 8 — CI workflow

Add `.github/workflows/ci.yml` from [reference.md](../init-project/reference.md) — pick **playground** or **live** template.

Web repos need GitHub secret `ACCESS_TO_VPS_WWWDATA_FROM_GITHUB_ACTIONS`.

| Mode | CI |
|------|-----|
| playground | Push `main` → deploy `…/staging` only (no production job) |
| live | Push `main` → staging · `workflow_dispatch` → production |

---

## Gate 9 — Verify & handoff

### Web

```bash
cd "${WORKSPACE}"
php artisan test
"${SHARED_ASSETS}/scripts/init-project/verify.sh" "${STAGING_FQDN}"
# live only:
"${SHARED_ASSETS}/scripts/init-project/verify.sh" "${PRODUCTION_FQDN}"
```

### Handoff table

| Item | Playground | Live | Expo |
|------|------------|------|------|
| Repo | `github.com/monjizeen/{PROJECT}` | same | same |
| Staging / app URL | `https://{PROJECT}.mnjz.in` | `https://staging.{domain}` | N/A |
| Production | — (same as above) | `https://app.{domain}` | App store / EAS |
| MORA agent | `domains/monjizeen/agents/{PROJECT}/` | same | same |

---

## Rules

- **Idempotent** — scripts safe to re-run.
- **Secrets** — never commit `.env`; never print client secrets.
- **No kawader scaffold** — use `templates/web-app` only.
- **No empty scaffold** — Gate 3 must include purpose-shaped mock data + UI that shows it before first push.
- **No slapdash UI** — Gate 3 must meet the Design quality bar (hierarchy, type, spacing, atmosphere, Enjaz-first).
- **Shell nav** — logged out: Theme toggle + Login; logged in: logo → dashboard, Theme toggle + Sign out only (no Dashboard link); brand = project name not `App`.
- **Light/dark toggle** — every web project ships a working theme toggle (header + auth screens); persist preference; no FOUC.
- **Pauses** — Gate 5 waits for human; Gate 7 optional per Gate 1.
- **Executor** — run commands yourself; Gates 1 and 5 need Omar input.
- **Resume** — Omar can say `/new-project continue {project}` to pick up at first incomplete gate.
- **No dual live** — never `{project}.mnjz.in` as production **and** `app.{domain}` as production at the same time.
