---
name: monjizeen-remote
description: >
  Control Monjizeen from Cursor or Telegram — list/create tickets, change status,
  post work updates via API. Use when Omar says create ticket, list tickets, work
  update, monjizeen remote, or /mz. Staging first; prod after GH Actions deploy.
---

# Monjizeen remote control

Drive Monjizeen **without opening the website**. Same tool on Cursor (Mac) and Telegram (VPS).

## Env (required)

| Var | Meaning |
|-----|---------|
| `MONJIZEEN_API_URL` | Staging: `https://staging.monjizeen.com` (confirm live URL). Prod later: `https://app.monjizeen.com` |
| `MONJIZEEN_API_TOKEN` | Same secret as server `MORA_API_TOKEN` |

Cursor Mac: put in shell env or `~/.cursor/monjizeen-remote.env` (export before use).  
Telegram VPS: add to `/home/claude/telegram-bot/.env`.

## CLI (preferred)

```bash
SCRIPT="$MORA_HUB/scripts/monjizeen-remote.js"
# Cursor Mac default:
SCRIPT="${MORA_HUB:-$(cat ~/.cursor/mono-root 2>/dev/null | head -1)/mora}/scripts/monjizeen-remote.js"

node "$SCRIPT" health
node "$SCRIPT" projects
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

1. Default target = **staging** until Omar says prod is OK.
2. Never invent ticket/project IDs — list first.
3. After create/update/status, show Omar the short result (id, title, status).
4. Do **not** print the API token.
5. If health fails: token missing on server or wrong URL — tell Omar in plain language.

## Telegram shortcuts

Omar may say `/mz tickets`, `/mz create …`, `/mz update …` — bot runs the same CLI.
Plain chat (“create a ticket for …”) → MORA uses this skill + CLI.
