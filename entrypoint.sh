#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Runs Electron in headless mode — no display server required.
# The Fastify web server is the only UI (MAESTRO_WEB_PORT + MAESTRO_WEB_TOKEN).
# ─────────────────────────────────────────────────────────────────────────────

ELECTRON_BIN="/app/node_modules/electron/dist/electron"

# ── D-Bus setup ──────────────────────────────────────────────────────────────
# Chromium/Electron checks the system bus socket on startup; if the socket
# exists but the daemon isn't running (e.g. after a container restart) it
# crashes with property_cache.cc(46) Check failed.  Clean up stale state then
# start a fresh daemon before launching Electron.
echo "[entrypoint] Setting up D-Bus..."
rm -f /var/run/dbus/pid /var/run/dbus/system_bus_socket
mkdir -p /var/run/dbus
dbus-daemon --system --fork 2>/dev/null || true
# Wait until the socket appears (up to 3 seconds)
for i in 1 2 3; do
  [ -S /var/run/dbus/system_bus_socket ] && break
  sleep 1
done
echo "[entrypoint] D-Bus ready (socket: $([ -S /var/run/dbus/system_bus_socket ] && echo yes || echo no))"

# No desktop session bus in a container
export DBUS_SESSION_BUS_ADDRESS="disabled:"

echo "[entrypoint] Launching Maestro (headless Electron)..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox              required in LXC (no kernel namespace isolation)
# --headless=old            "old headless" avoids the D-Bus property-cache CHECK
#                           that fires in new headless mode inside containers
# --disable-gpu             no GPU in container
# --disable-dev-shm-usage   use /tmp instead of /dev/shm
# --disable-setuid-sandbox  required without user namespaces
# --in-process-gpu          avoid spawning a separate GPU process
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --headless=old \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-setuid-sandbox \
  --in-process-gpu \
  "$@"
