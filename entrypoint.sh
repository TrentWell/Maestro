#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Uses Xvfb virtual display + D-Bus to satisfy Electron/Chromium's runtime
# requirements without physical hardware.
# The Fastify web server is the only UI (MAESTRO_WEB_PORT + MAESTRO_WEB_TOKEN).
# ─────────────────────────────────────────────────────────────────────────────

ELECTRON_BIN="/app/node_modules/electron/dist/electron"
DISPLAY_NUM=99

# ── D-Bus (system bus — Electron checks socket on startup) ───────────────────
echo "[entrypoint] Setting up D-Bus..."
rm -f /var/run/dbus/pid /var/run/dbus/system_bus_socket
mkdir -p /var/run/dbus
dbus-daemon --system --fork 2>/dev/null || true
for i in 1 2 3; do
  [ -S /var/run/dbus/system_bus_socket ] && break
  sleep 1
done
echo "[entrypoint] D-Bus ready (socket: $([ -S /var/run/dbus/system_bus_socket ] && echo yes || echo no))"

# ── Xvfb virtual display ─────────────────────────────────────────────────────
# Running Electron via Xvfb instead of --headless avoids the Chromium
# property_cache.cc CHECK failure that fires in new/old headless mode when
# org.freedesktop.UPower is absent from the system D-Bus.
echo "[entrypoint] Starting Xvfb on :${DISPLAY_NUM}..."
rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM}
Xvfb :${DISPLAY_NUM} -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
export DISPLAY=:${DISPLAY_NUM}

# Wait for Xvfb to be ready
for i in $(seq 1 10); do
  xdpyinfo -display :${DISPLAY_NUM} >/dev/null 2>&1 && break
  sleep 0.5
done
echo "[entrypoint] Xvfb ready on :${DISPLAY_NUM}"

echo "[entrypoint] Launching Maestro..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox              required in LXC (no kernel namespace isolation)
# --disable-gpu             no GPU in container (SwiftShader software render)
# --disable-dev-shm-usage   use /tmp instead of /dev/shm
# --disable-setuid-sandbox  required without user namespaces
# --in-process-gpu          run GPU stub in main process
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-setuid-sandbox \
  --in-process-gpu \
  "$@"
