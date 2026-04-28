#!/bin/sh
set -e

PICOCLAW_HOME="${HOME}/.picoclaw"

mkdir -p "${PICOCLAW_HOME}/workspace"
mkdir -p "${PICOCLAW_HOME}/sessions"
mkdir -p "${PICOCLAW_HOME}/cron"

rm -f "${PICOCLAW_HOME}/.picoclaw.pid"

# Generate config.json from env vars so env.Parse() is triggered and channels are configured.
# Without a config file, DefaultConfig() is returned directly and env vars are ignored.
if [ ! -f "${PICOCLAW_HOME}/config.json" ]; then
    TELEGRAM_TOKEN="${PICOCLAW_CHANNELS_TELEGRAM_TOKEN:-}"
    PROVIDER="${PICOCLAW_AGENTS_DEFAULTS_PROVIDER:-}"
    MODEL="${PICOCLAW_AGENTS_DEFAULTS_MODEL:-}"

    cat > "${PICOCLAW_HOME}/config.json" <<EOF
{
  "version": 3,
  "agents": {
    "defaults": {
      "provider": "${PROVIDER}",
      "model_name": "${MODEL}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "type": "telegram",
      "settings": {
        "token": "${TELEGRAM_TOKEN}"
      }
    }
  }
}
EOF
fi

exec picoclaw gateway --allow-empty
