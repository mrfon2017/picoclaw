#!/bin/sh
set -e

PICOCLAW_HOME="${HOME}/.picoclaw"

mkdir -p "${PICOCLAW_HOME}/workspace"
mkdir -p "${PICOCLAW_HOME}/sessions"
mkdir -p "${PICOCLAW_HOME}/cron"

rm -f "${PICOCLAW_HOME}/.picoclaw.pid"

# Force config regeneration if RESET_CONFIG=1 is set
if [ "${RESET_CONFIG:-0}" = "1" ]; then
    rm -f "${PICOCLAW_HOME}/config.json"
fi

# Generate config.json if missing.
# Channel Enabled and model API keys have no env tags in picoclaw Go code,
# so they must be written to config.json directly from Railway env vars.
if [ ! -f "${PICOCLAW_HOME}/config.json" ]; then
    TELEGRAM_TOKEN="${PICOCLAW_CHANNELS_TELEGRAM_TOKEN:-}"
    OR_API_KEY="${PICOCLAW_PROVIDERS_OPENROUTER_API_KEY:-}"
    MODEL="${PICOCLAW_AGENTS_DEFAULTS_MODEL:-google/gemini-2.5-flash-lite}"
    MODEL_NAME="openrouter-default"

    cat > "${PICOCLAW_HOME}/config.json" <<EOF
{
  "version": 3,
  "agents": {
    "defaults": {
      "provider": "openrouter",
      "model_name": "${MODEL_NAME}"
    }
  },
  "model_list": [
    {
      "model_name": "${MODEL_NAME}",
      "provider": "openrouter",
      "model": "${MODEL}",
      "api_base": "https://openrouter.ai/api/v1",
      "api_keys": ["${OR_API_KEY}"]
    }
  ],
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
