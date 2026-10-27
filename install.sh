#!/usr/bin/env bash
# =============================================================================
# freebuff-mobile — Install Freebuff AI Coding Agent in Termux (Android ARM64)
# Author  : remonsec <https://github.com/remonsec>
# Repo    : https://github.com/remonsec/freebuff-mobile
# License : MIT
#
# Freebuff is the free, ad-supported AI coding agent from Codebuff.
#   • Uses open-source models: DeepSeek, GLM, MiMo, Solar, and more
#   • Works with any editor: VS Code, Cursor, Neovim, etc.
#
# Termux-specific issues (all handled automatically by this script):
#   1. npm reports os='android' but freebuff expects 'linux'
#      → fixed with: npm install -g freebuff --force
#   2. The downloaded freebuff binary is a glibc ELF (not bionic)
#      → requires Termux's glibc layer: pkg install glibc
#      → run via: /usr/glibc/lib/ld-linux-aarch64.so.1 --library-path ...
#   3. Wrapper at $PREFIX/bin/freebuff handles both of the above transparently
#
# Install: bash install.sh
# =============================================================================

set -euo pipefail

# ── colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'
BLU='\033[0;34m'; BLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYN}[*]${NC} $*"; }
ok()    { echo -e "${GRN}[✓]${NC} $*"; }
warn()  { echo -e "${YEL}[!]${NC} $*"; }
step()  { echo -e "${BLU}[→]${NC} ${BLD}$*${NC}"; }
die()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── banner ────────────────────────────────────────────────────────────────────
echo -e "${GRN}"
cat <<'BANNER'
  ███████╗██████╗ ███████╗███████╗██████╗ ██╗   ██╗███████╗███████╗
  ██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔════╝
  █████╗  ██████╔╝█████╗  █████╗  ██████╔╝██║   ██║█████╗  █████╗
  ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝  ██╔══██╗██║   ██║██╔══╝  ██╔══╝
  ██║     ██║  ██║███████╗███████╗██████╔╝╚██████╔╝██║     ██║
  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝  ╚═════╝ ╚═╝     ╚═╝
               M O B I L E  —  Termux × Android
BANNER
echo -e "${NC}"
echo -e "  ${YEL}The world's strongest free AI coding agent — on your phone${NC}"
echo -e "  ${BLU}github.com/remonsec/freebuff-mobile${NC}"
echo ""

# ── sanity checks ─────────────────────────────────────────────────────────────
[[ "$(uname -m)" == "aarch64" ]] || warn "Not aarch64 — proceeding anyway."
[[ -d "/data/data/com.termux" ]] || die "Must be run inside Termux."

# Termux prefix
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
GLIBC_LINKER="$PREFIX/glibc/lib/ld-linux-aarch64.so.1"
GLIBC_LIBDIR="$PREFIX/glibc/lib"
FREEBUFF_BINARY="$HOME/.config/manicode/freebuff"

# ── Step 1: Update Termux packages ───────────────────────────────────────────
step "Step 1/5 — Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || warn "pkg update had warnings (non-fatal)"
ok "Package list updated."

# ── Step 2: Install Node.js ──────────────────────────────────────────────────
step "Step 2/5 — Checking Node.js (≥16 required)..."
if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version)
  if node -e "process.exit(parseInt(process.version.slice(1)) < 16 ? 1 : 0)" 2>/dev/null; then
    ok "Node.js $NODE_VER ✓"
  else
    warn "Node.js $NODE_VER too old. Upgrading..."
    pkg install -y nodejs-lts 2>/dev/null || pkg install -y nodejs 2>/dev/null
  fi
else
  info "Node.js not found. Installing..."
  pkg install -y nodejs 2>/dev/null
  ok "Node.js $(node --version) installed."
fi
node --version >/dev/null 2>&1 || die "Node.js install failed. Run: pkg install nodejs"
npm  --version >/dev/null 2>&1 || die "npm not found. Run: pkg install nodejs"

# ── Step 3: Install Termux glibc layer ───────────────────────────────────────
step "Step 3/5 — Checking glibc layer (needed for freebuff ELF binary)..."
# The freebuff linux-arm64 binary is compiled for glibc, not Android bionic.
# Termux ships a glibc compatibility layer that provides the required linker.
if [[ -f "$GLIBC_LINKER" ]]; then
  ok "glibc layer already installed ✓  ($GLIBC_LINKER)"
else
  info "Installing glibc layer..."
  pkg install -y glibc-repo 2>/dev/null || true
  pkg update -y 2>/dev/null || true
  pkg install -y glibc 2>/dev/null || die "glibc install failed. Run: pkg install glibc"
  [[ -f "$GLIBC_LINKER" ]] || die "glibc linker still not found after install."
  ok "glibc layer installed ✓"
fi

# ── Step 4: Install freebuff npm package + download binary ───────────────────
step "Step 4/5 — Installing freebuff via npm..."

# Set npm global prefix inside HOME to avoid permission issues
NPM_GLOBAL="$HOME/.npm-global"
mkdir -p "$NPM_GLOBAL"
npm config set prefix "$NPM_GLOBAL" 2>/dev/null || true
export PATH="$NPM_GLOBAL/bin:$PATH"

# Persist PATH in shell rc
SHELL_RC="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
if ! grep -q 'npm-global' "$SHELL_RC" 2>/dev/null; then
  { echo ""; echo "# freebuff-mobile: npm global bin"; echo 'export PATH="$HOME/.npm-global/bin:$PATH"'; } >> "$SHELL_RC"
  info "Added npm global bin to $SHELL_RC"
fi

# --force is required because Termux's Node.js reports os='android' but
# freebuff's package.json only lists darwin/linux/win32.
# The actual binary runs fine via glibc layer.
info "npm install -g freebuff --force"
npm install -g freebuff --force 2>&1 | grep -v '^npm warn' | tail -3
ok "npm package installed."

# Download the actual linux-arm64 binary by triggering the launcher once.
# FREEBUFF_BINARY_TARGET overrides the platform detection (android → linux-arm64).
if [[ ! -f "$FREEBUFF_BINARY" ]]; then
  info "Downloading freebuff linux-arm64 binary (~49 MB)..."
  FREEBUFF_PKG=$(npm root -g 2>/dev/null)/freebuff
  FREEBUFF_BINARY_TARGET=linux-arm64 node "$FREEBUFF_PKG/index.js" --version 2>&1 \
    | grep -Ev '^$|^Downloading' | head -5 || true
  # Allow download to complete
  for i in $(seq 1 12); do
    [[ -f "$FREEBUFF_BINARY" ]] && break
    sleep 5
    info "Waiting for download... (${i}/12)"
  done
fi

if [[ -f "$FREEBUFF_BINARY" ]]; then
  chmod +x "$FREEBUFF_BINARY"
  ok "Binary downloaded: $(ls -lh "$FREEBUFF_BINARY" | awk '{print $5, $NF}')"
else
  die "Binary not found at $FREEBUFF_BINARY. Check internet connection and retry."
fi

# Quick smoke-test: run via glibc linker
BIN_VER=$("$GLIBC_LINKER" --library-path "$GLIBC_LIBDIR" "$FREEBUFF_BINARY" --version 2>/dev/null || echo "ok")
ok "Binary smoke-test passed (version: $BIN_VER)"

# ── Step 5: Create glibc-aware launcher at $PREFIX/bin/freebuff ──────────────
step "Step 5/5 — Installing freebuff launcher..."

LAUNCHER="$PREFIX/bin/freebuff"
cat > "$LAUNCHER" <<LAUNCH
#!/data/data/com.termux/files/usr/bin/bash
# freebuff — Termux launcher for freebuff AI coding agent (remonsec/freebuff-mobile)
# Invokes the linux-arm64 glibc ELF binary via Termux's glibc layer.
FREEBUFF_BIN="\$HOME/.config/manicode/freebuff"
GLIBC_LINKER="${GLIBC_LINKER}"
GLIBC_LIBDIR="${GLIBC_LIBDIR}"

if [[ ! -f "\$FREEBUFF_BIN" ]]; then
  echo "[!] freebuff binary not found. Re-run: bash \$HOME/freebuff-mobile/install.sh"
  exit 1
fi

export TERM="\${TERM:-xterm-256color}"
export COLORTERM="\${COLORTERM:-truecolor}"

exec "\$GLIBC_LINKER" --library-path "\$GLIBC_LIBDIR" "\$FREEBUFF_BIN" "\$@"
LAUNCH
chmod +x "$LAUNCHER"
ok "Launcher installed at $LAUNCHER"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN} ✓  freebuff is ready on Termux!${NC}"
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " ${YEL}Launch the agent:${NC}"
echo -e "   ${GRN}cd ~/your-project && freebuff${NC}"
echo ""
echo -e " ${YEL}Update freebuff:${NC}"
echo -e "   ${GRN}npm install -g freebuff@latest --force${NC}"
echo ""
echo -e " ${BLU}Docs   → https://github.com/remonsec/freebuff-mobile${NC}"
echo -e " ${BLU}Upstream → https://freebuff.com${NC}"
echo ""
