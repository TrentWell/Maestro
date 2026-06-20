#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Starts a virtual display then launches Electron with the Maestro app.
# ─────────────────────────────────────────────────────────────────────────────

DISPLAY_NUM=":99"
ELECTRON_BIN="/app/node_modules/electron/dist/electron"

echo "[entrypoint] Starting virtual display on ${DISPLAY_NUM}..."
Xvfb "${DISPLAY_NUM}" -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# Give Xvfb a moment to initialize
sleep 1

# Verify display is up
if ! kill -0 $XVFB_PID 2>/dev/null; then
  echo "[entrypoint] ERROR: Xvfb failed to start"
  exit 1
fi

export DISPLAY="${DISPLAY_NUM}"

echo "[entrypoint] Launching Maestro (Electron)..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox required in LXC containers (kernel namespaces not available)
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --disable-gpu \
  --disable-software-rasterizer \
  "$@"
