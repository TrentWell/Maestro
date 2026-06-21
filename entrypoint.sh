#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Starts a virtual display then launches Electron with the Maestro app.
# ─────────────────────────────────────────────────────────────────────────────

DISPLAY_NUM=":99"
ELECTRON_BIN="/app/node_modules/electron/dist/electron"

echo "[entrypoint] Starting virtual display on ${DISPLAY_NUM}..."
Xvfb "${DISPLAY_NUM}" -screen 0 1280x800x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# Wait for Xvfb to be ready (check for lock file)
for i in $(seq 1 15); do
  if [ -f "/tmp/.X99-lock" ]; then
    echo "[entrypoint] Xvfb ready (${i}s)"
    break
  fi
  sleep 1
done

if ! kill -0 $XVFB_PID 2>/dev/null; then
  echo "[entrypoint] ERROR: Xvfb failed to start"
  exit 1
fi

export DISPLAY="${DISPLAY_NUM}"

echo "[entrypoint] Launching Maestro (Electron)..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox            required in LXC containers
# --disable-dev-shm-usage use /tmp instead of /dev/shm (important in containers)
# --use-gl=swiftshader    explicit software GL (Xvfb has no GPU, SwiftShader fills in)
# --disable-extensions    skip Chrome extension initialization
# Note: do NOT use --disable-gpu or --disable-software-rasterizer —
#   those strip SwiftShader and prevent BrowserWindow from initializing
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --disable-dev-shm-usage \
  --use-gl=swiftshader \
  --disable-extensions \
  "$@"
