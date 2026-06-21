#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Runs Electron in headless mode — no display server required.
# The Fastify web server is the only UI (MAESTRO_WEB_PORT + MAESTRO_WEB_TOKEN).
# ─────────────────────────────────────────────────────────────────────────────

ELECTRON_BIN="/app/node_modules/electron/dist/electron"

# ── D-Bus (Chromium/Electron requires a system bus socket or it crashes) ─────
# property_cache.cc asserts when the system bus is absent; starting dbus-daemon
# before Electron prevents the CHECK failure crash loop.
echo "[entrypoint] Starting D-Bus system daemon..."
mkdir -p /var/run/dbus
dbus-daemon --system --fork 2>/dev/null || true
sleep 0.5

# Suppress session-bus complaints (no desktop environment in container)
export DBUS_SESSION_BUS_ADDRESS="disabled:"

echo "[entrypoint] Launching Maestro (headless Electron)..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox                        required in LXC (no kernel namespace isolation)
# --headless                          run without a display server
# --disable-gpu                       no GPU in container
# --disable-dev-shm-usage             use /tmp instead of /dev/shm
# --disable-setuid-sandbox            required without user namespaces
# --in-process-gpu                    avoid spawning a separate GPU process
# --disable-features=XdgPortal,...    skip xdg-portal D-Bus calls (file dialogs etc.)
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --headless \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-setuid-sandbox \
  --in-process-gpu \
  --disable-features=XdgPortal,DesktopScreenshots \
  "$@"
