---
name: monjizeen-remote
description: >
  Control Monjizeen from Cursor or Telegram — list/create tickets, change status,
  post work updates, manage project links via API. Use when Omar says create ticket,
  list tickets, work update, add project link, monjizeen remote, or /mz.
  Staging first; live after production deploy + URL switch.
---

# Monjizeen remote control

Drive Monjizeen **without opening the website**. Same tool on Cursor (Mac) and Telegram (VPS).

## Env (required)

| Var | Meaning |
|-----|---------|
| `MONJIZEEN_API_URL` | Staging: `https://staging.monjizeen.com`. Live: `https://app.monjizeen.com` |
| `MONJIZEEN_API_TOKEN` | Same secret as server `MORA_API_TOKEN` |

Cursor Mac: `~/.cursor/secrets/monjizeen-remote.env` (or shell export).  
Telegram VPS: `/home/claude/telegram-bot/.env`.

## CLI (preferred)

```bash
SCRIPT="$MORA_HUB/scripts/monjizeen-remote.js"
# Cursor Mac default:
SCRIPT="${MORA_HUB:-$(cat ~/.cursor/mora-hub 2>/dev/null)/mora}/scripts/monjizeen-remote.js"

node "$SCRIPT" health
node "$SCRIPT" projects
node "$SCRIPT" links --project 3
node "$SCRIPT" add-link --project 3 --label "Github repo" --url https://github.com/org/repo
node "$SCRIPT" delete-link --project 3 --link 9
node "$SCRIPT" tickets
node "$SCRIPT" tickets --project 3
node "$SCRIPT" ticket 12
node "$SCRIPT" create-ticket --project 3 --title "Fix login" --desc "Details"
node "$SCRIPT" status 12 --to in_progress
node "$SCRIPT" update 12 --minutes 30 --text "Shipped draft UI"
```

Minutes must be one of: 15, 30, 45, 60, 75, 90, 105, 120.

## Status values

`backlog` · `selected_for_work` · `in_progress` · `ready_for_peer_review` · `in_peer_review` · `peer_comments_added` · `ready_for_client_review` · `in_client_review` · `client_comments_added` · `done` · `cancelled`

## Rules

1. Default target = **staging** until Omar says live / prod is OK (then switch `MONJIZEEN_API_URL` to `https://app.monjizeen.com`).
2. Never invent ticket/project/link IDs — list first.
3. After create/update/status/add-link, show Omar the short result (id, title/label, status/url).
4. Do **not** print the API token.
5. If health fails: token missing on server, wrong URL, or live not deployed yet — tell Omar in plain language.
6. Live `app.monjizeen.com` needs production deploy + `MORA_API_TOKEN` in prod `.env` before remote works there.

## Telegram shortcuts

Omar may say `/mz tickets`, `/mz links --project 3`, `/mz add-link …`, `/mz update …` — bot runs the same CLI.
Plain chat (“create a ticket for …”, “add github link to monjizeen project”) → MORA uses this skill + CLI.
