#!/bin/sh
set -e

PICOCLAW_HOME="${HOME}/.picoclaw"

mkdir -p "${PICOCLAW_HOME}/workspace"
mkdir -p "${PICOCLAW_HOME}/sessions"
mkdir -p "${PICOCLAW_HOME}/cron"

rm -f "${PICOCLAW_HOME}/.picoclaw.pid"

# Create a minimal config.json if missing so env.Parse() is called by the Go config loader.
# Without it, DefaultConfig() is returned directly and env vars like
# PICOCLAW_GATEWAY_PORT / PICOCLAW_GATEWAY_HOST are ignored.
if [ ! -f "${PICOCLAW_HOME}/config.json" ]; then
    cat > "${PICOCLAW_HOME}/config.json" <<'EOF'
{"version":3}
EOF
fi

exec picoclaw gateway --allow-empty
