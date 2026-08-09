#!/usr/bin/env bash
# Register (or verify) a per-repo GitHub Actions self-hosted runner on the VPS.
#
# Why: CI templates use `runs-on: self-hosted`. Without a runner registered to
# THAT repo on the VPS, deploy jobs queue forever (~24h) then cancel.
#
# Usage:
#   register-vps-runner.sh <project>
#   register-vps-runner.sh <project> --force   # reconfigure even if online
#
# Requires: gh auth (admin:repo_hook / repo), SSH to VPS (BatchMode).
# Never copies another runner dir (that broke enjaz once) — always fresh download.
#
# Env (optional):
#   GH_ORG          default monjizeen
#   VPS_SSH_HOST    default vps (or from ~/.cursor/secrets/monjizeen.env)
#   VPS_SSH_USER    default root

set -euo pipefail

PROJECT="${1:?usage: register-vps-runner.sh <project> [--force]}"
FORCE=0
if [[ "${2:-}" == "--force" ]]; then
  FORCE=1
fi

GH_ORG="${GH_ORG:-monjizeen}"
REPO="${GH_ORG}/${PROJECT}"
ORG_SECRETS="${HOME}/.cursor/secrets/monjizeen.env"

if [[ -f "${ORG_SECRETS}" ]]; then
  # shellcheck disable=SC1090
  set -a && source "${ORG_SECRETS}" && set +a
fi

VPS_SSH_HOST="${VPS_SSH_HOST:-vps}"
VPS_SSH_USER="${VPS_SSH_USER:-root}"
VPS_SSH="${VPS_SSH_USER}@${VPS_SSH_HOST}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)

echo "register-vps-runner: repo=${REPO}"

if ! gh repo view "${REPO}" >/dev/null 2>&1; then
  echo "error: cannot access ${REPO} — create the GitHub repo first (Gate 2)" >&2
  exit 1
fi

runner_online() {
  local count
  count="$(gh api "repos/${REPO}/actions/runners" --jq '[.runners[] | select(.status=="online")] | length' 2>/dev/null || echo 0)"
  [[ "${count}" != "0" && "${count}" != "" ]]
}

if runner_online && [[ "${FORCE}" -eq 0 ]]; then
  gh api "repos/${REPO}/actions/runners" --jq '.runners[] | select(.status=="online") | "ok: online runner \(.name) (id=\(.id))"'
  exit 0
fi

echo "register-vps-runner: fetching registration token + runner version"
TOKEN="$(gh api -X POST "repos/${REPO}/actions/runners/registration-token" --jq .token)"
if [[ -z "${TOKEN}" || "${TOKEN}" == "null" ]]; then
  echo "error: empty registration token — need repo admin / actions permission" >&2
  exit 1
fi

VER="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
echo "register-vps-runner: runner version ${VER}"

echo "register-vps-runner: SSH install on ${VPS_SSH}"
# Pass secrets via env on remote; do not echo TOKEN.
ssh "${SSH_OPTS[@]}" "${VPS_SSH}" \
  "TOKEN='${TOKEN}' VER='${VER}' PROJECT='${PROJECT}' GH_ORG='${GH_ORG}' FORCE='${FORCE}' bash -s" <<'EOF'
set -euo pipefail

HOST="$(hostname -s)"
NAME="${HOST}-${PROJECT}"
DST="/srv/github-actions-runner-${PROJECT}"
URL="https://github.com/${GH_ORG}/${PROJECT}"
SVC_GLOB="actions.runner.${GH_ORG}-${PROJECT}.${NAME}.service"

if [[ -f "${DST}/.runner" && "${FORCE}" != "1" ]]; then
  echo "Runner dir exists at ${DST}; ensuring service is up..."
  if systemctl list-unit-files "${SVC_GLOB}" >/dev/null 2>&1 || systemctl cat "${SVC_GLOB}" >/dev/null 2>&1; then
    systemctl start "${SVC_GLOB}" || true
  elif [[ -x "${DST}/svc.sh" ]]; then
    (cd "${DST}" && ./svc.sh start) || true
  fi
  sleep 2
  if systemctl is-active --quiet "${SVC_GLOB}" 2>/dev/null; then
    echo "service active: ${SVC_GLOB}"
    exit 0
  fi
  echo "existing config but service not active — will reconfigure with --replace"
fi

mkdir -p "${DST}"
cd "${DST}"

if [[ ! -f bin/Runner.Listener ]]; then
  echo "Downloading actions-runner ${VER}..."
  curl -fsSL -o "actions-runner-linux-x64-${VER}.tar.gz" \
    "https://github.com/actions/runner/releases/download/v${VER}/actions-runner-linux-x64-${VER}.tar.gz"
  tar xzf "actions-runner-linux-x64-${VER}.tar.gz"
  rm -f "actions-runner-linux-x64-${VER}.tar.gz"
fi

chown -R www-data:www-data "${DST}"

# Stop old unit if force / reconfig
if [[ -x ./svc.sh ]]; then
  ./svc.sh stop 2>/dev/null || true
  ./svc.sh uninstall 2>/dev/null || true
fi

sudo -u www-data ./config.sh --unattended \
  --url "${URL}" \
  --token "${TOKEN}" \
  --name "${NAME}" \
  --labels "vps" \
  --work _work \
  --replace

./svc.sh install www-data
./svc.sh start
sleep 2

# Discover actual unit name from .service file
if [[ -f .service ]]; then
  # shellcheck disable=SC1091
  source .service
  echo "service=${SVC_NAME:-unknown}"
  systemctl is-active "${SVC_NAME}"
else
  systemctl is-active "${SVC_GLOB}" || systemctl list-units --type=service --all | grep -i "${PROJECT}" || true
fi

echo "DONE name=${NAME} path=${DST}"
EOF

echo "register-vps-runner: waiting for GitHub to show online..."
for i in $(seq 1 18); do
  if runner_online; then
    gh api "repos/${REPO}/actions/runners" --jq '.runners[] | select(.status=="online") | "ok: online runner \(.name) (id=\(.id))"'
    exit 0
  fi
  sleep 5
done

echo "error: runner installed but not online in GitHub after ~90s — check VPS systemd for ${PROJECT}" >&2
gh api "repos/${REPO}/actions/runners" --jq '.runners // []' >&2 || true
exit 1
