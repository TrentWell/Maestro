#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Maestro Container Entrypoint
# Runs Electron in headless mode — no display server required.
# The Fastify web server is the only UI (MAESTRO_WEB_PORT + MAESTRO_WEB_TOKEN).
# ─────────────────────────────────────────────────────────────────────────────

ELECTRON_BIN="/app/node_modules/electron/dist/electron"

echo "[entrypoint] Launching Maestro (headless Electron)..."
echo "[entrypoint] Web port : ${MAESTRO_WEB_PORT:-not set}"
echo "[entrypoint] Web token: ${MAESTRO_WEB_TOKEN:-not set}"

# --no-sandbox              required in LXC containers (no kernel namespace isolation)
# --headless                run without a display server (Chromium new headless)
# --disable-gpu             disable GPU hardware acceleration (no GPU in container)
# --disable-dev-shm-usage   use /tmp instead of /dev/shm (important in Docker)
# --disable-setuid-sandbox  required without user namespaces
# --in-process-gpu          run GPU stub in main process (avoids spawning GPU process)
exec "${ELECTRON_BIN}" /app \
  --no-sandbox \
  --headless \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-setuid-sandbox \
  --in-process-gpu \
  "$@"
