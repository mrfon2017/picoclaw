#!/bin/sh
set -e

# Store everything on the persistent volume mounted at /data
export PICOCLAW_HOME="/data/.picoclaw"

mkdir -p "${PICOCLAW_HOME}/workspace"
mkdir -p "${PICOCLAW_HOME}/sessions"
mkdir -p "${PICOCLAW_HOME}/cron"

# Seed default workspace files (MEMORY.md, AGENT.md, SOUL.md, skills/) on first run
DEFAULT_WORKSPACE="/usr/local/share/picoclaw/workspace"
WORKSPACE="${PICOCLAW_HOME}/workspace"

if [ -d "${DEFAULT_WORKSPACE}" ]; then
    # Copy each file only if it doesn't exist yet (busybox-safe)
    find "${DEFAULT_WORKSPACE}" -type d | while read dir; do
        target="${WORKSPACE}${dir#${DEFAULT_WORKSPACE}}"
        mkdir -p "$target"
    done
    find "${DEFAULT_WORKSPACE}" -type f | while read src; do
        target="${WORKSPACE}${src#${DEFAULT_WORKSPACE}}"
        if [ ! -f "$target" ]; then
            cp "$src" "$target"
        fi
    done
fi

# Also place MEMORY.md at workspace root so the model can find it
# regardless of whether it uses "MEMORY.md" or "memory/MEMORY.md"
MEMORY_SRC="${WORKSPACE}/memory/MEMORY.md"
MEMORY_ROOT="${WORKSPACE}/MEMORY.md"
if [ -f "${MEMORY_SRC}" ] && [ ! -f "${MEMORY_ROOT}" ]; then
    ln -sf "${MEMORY_SRC}" "${MEMORY_ROOT}"
fi

rm -f "${PICOCLAW_HOME}/.picoclaw.pid"

# Force config regeneration if RESET_CONFIG=1 is set
if [ "${RESET_CONFIG:-0}" = "1" ]; then
    rm -f "${PICOCLAW_HOME}/config.json"
fi

# Generate config.json if missing.
# Channel Enabled and model API keys have no env tags in picoclaw Go code,
# so they must be written to config.json directly from Railway env vars.
# Note: top-level channels field is "channel_list" in version 3 Config struct.
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
  "channel_list": {
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
