#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for pnpm/pnpm.io
# Runs on existing source tree (no clone). Installs deps, runs pre-build steps, builds.

# --- Node version: install Node 22 via n ---
echo "[INFO] Setting up Node 22 via n..."
export N_PREFIX="/tmp/n-pnpmio"
n install 22
export PATH="/tmp/n-pnpmio/bin:$PATH"
echo "[INFO] Node version: $(node -v)"

# --- Package manager: pnpm@10.30.0 via corepack ---
echo "[INFO] Setting up pnpm@10.30.0 via corepack..."
corepack enable
corepack prepare pnpm@10.30.0 --activate
echo "[INFO] pnpm version: $(pnpm --version)"

# --- Dependencies ---
echo "[INFO] Installing dependencies..."
# Use --no-frozen-lockfile because the pnpm-lock.yaml uses a multi-document YAML format
# that may not be supported by all pnpm versions
pnpm install --no-frozen-lockfile

# --- Pre-build step: copy-docs (needed for versioned_docs/version-11.x) ---
echo "[INFO] Running copy-docs (needed for versioned_docs/version-11.x)..."
pnpm run copy-docs

# --- Build ---
echo "[INFO] Running build..."
pnpm run build

echo "[DONE] Build complete."
