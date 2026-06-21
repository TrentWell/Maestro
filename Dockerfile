# ─────────────────────────────────────────────────────────────────────────────
# Maestro — Containerized Build
# Runs Electron in headless mode with D-Bus for Chromium desktop integration.
# Access the app via the built-in Fastify web server.
#
# Required env vars:
#   MAESTRO_WEB_PORT   — port to expose (e.g. 9300)
#   MAESTRO_WEB_TOKEN  — URL token for the web UI (e.g. "antigravity")
#                        Web UI will be at http://<host>:<PORT>/<TOKEN>/
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM node:20-bookworm AS builder

# Native module build deps (node-pty, better-sqlite3, electron-rebuild)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ \
    libx11-dev libxkbfile-dev libsecret-1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies (postinstall runs electron-rebuild for node-pty + better-sqlite3)
COPY package*.json ./
RUN npm ci

# Build all targets: main (TS), renderer (Vite), web (Vite), CLI
COPY . .
RUN npm run build

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

# Electron runtime + Xvfb virtual display + system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # D-Bus + Xvfb virtual display (both required to run Electron in containers)
    dbus xvfb x11-utils \
    # Electron / Chromium runtime deps
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libgbm1 libgtk-3-0 libasound2 \
    libxss1 libxrandr2 libxfixes3 libxi6 libxtst6 \
    libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 \
    libxext6 libgconf-2-4 fonts-liberation \
    # Tools
    curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code (primary agent Maestro will drive)
RUN npm install -g @anthropic-ai/claude-code --unsafe-perm=true

WORKDIR /app

# Copy built app + node_modules (includes Electron binary + compiled native modules)
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Web server port (set via MAESTRO_WEB_PORT env var)
EXPOSE 9300

ENTRYPOINT ["/entrypoint.sh"]
