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

# Ensure memory dir and MEMORY.md always exist
mkdir -p "${WORKSPACE}/memory"
if [ ! -f "${WORKSPACE}/memory/MEMORY.md" ]; then
    cat > "${WORKSPACE}/memory/MEMORY.md" <<'MEMEOF'
# Agent Long-Term Memory

<!-- picoclaw writes important facts here between conversations -->
MEMEOF
fi

# Copy (not symlink) MEMORY.md to workspace root so the model finds it
# regardless of whether it calls read_file("MEMORY.md") or read_file("memory/MEMORY.md")
cp -f "${WORKSPACE}/memory/MEMORY.md" "${WORKSPACE}/MEMORY.md"

rm -f "${PICOCLAW_HOME}/.picoclaw.pid"

# Force config regeneration if RESET_CONFIG=1 is set
if [ "${RESET_CONFIG:-0}" = "1" ]; then
    rm -f "${PICOCLAW_HOME}/config.json"
fi

# Clear all sessions if CLEAR_SESSIONS=1 (fixes stuck/looping bot)
# Sessions are stored inside workspace/sessions/, not PICOCLAW_HOME/sessions/
if [ "${CLEAR_SESSIONS:-0}" = "1" ]; then
    rm -rf "${PICOCLAW_HOME}/workspace/sessions"
    mkdir -p "${PICOCLAW_HOME}/workspace/sessions"
    echo "Sessions cleared."
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

# Debug: verify MEMORY.md exists before starting gateway
echo "=== MEMORY.md check ==="
ls -la "${WORKSPACE}/MEMORY.md" 2>&1 || echo "MISSING: ${WORKSPACE}/MEMORY.md"
ls -la "${WORKSPACE}/memory/MEMORY.md" 2>&1 || echo "MISSING: ${WORKSPACE}/memory/MEMORY.md"
echo "Workspace: $(ls ${WORKSPACE}/ 2>&1)"
echo "======================"

exec picoclaw gateway --allow-empty
