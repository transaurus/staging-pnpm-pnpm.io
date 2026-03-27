#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/pnpm/pnpm.io"
BRANCH="main"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

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
echo "[INFO] .npmrc contents (using original bit.cloud registry for pnpm-scoped packages):"
cat .npmrc

echo "[INFO] Installing dependencies..."
# Use --no-frozen-lockfile because the pnpm-lock.yaml uses a multi-document YAML format
# that may not be supported by all pnpm versions
pnpm install --no-frozen-lockfile

# --- Pre-build step: copy-docs (needed for versioned_docs/version-11.x) ---
echo "[INFO] Running copy-docs first (needed for versioned_docs/version-11.x)..."
pnpm run copy-docs

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
