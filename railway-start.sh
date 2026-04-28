#!/bin/sh
set -e

export PICOCLAW_GATEWAY_PORT="${PORT:-18790}"
export PICOCLAW_GATEWAY_HOST="0.0.0.0"

mkdir -p "${HOME}/.picoclaw/workspace"
mkdir -p "${HOME}/.picoclaw/sessions"
mkdir -p "${HOME}/.picoclaw/cron"

rm -f "${HOME}/.picoclaw/.picoclaw.pid"

exec picoclaw gateway --allow-empty
