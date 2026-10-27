#!/usr/bin/env bash
# =============================================================================
# freebuff-mobile — Install Freebuff AI Coding Agent in Termux (Android ARM64)
# Author  : remonsec <https://github.com/remonsec>
# Repo    : https://github.com/remonsec/freebuff-mobile
# License : MIT
#
# Freebuff is the free, ad-supported AI coding agent from Codebuff.
#   • Free models: DeepSeek, GLM, MiMo, Solar, and more — no API key needed
#   • Works with any editor: VS Code, Cursor, Neovim, etc.
#
# Architecture notes:
#   Freebuff's linux-arm64 binary is compiled for glibc. Termux uses Android's
#   bionic libc, so the Termux glibc layer (pkg install glibc) is required to
#   provide the dynamic linker (ld-linux-aarch64.so.1). npm also reports
#   os='android'; --force bypasses this platform check safely since the
#   linux-arm64 binary runs correctly via the glibc layer.
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

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
GLIBC_LINKER="$PREFIX/glibc/lib/ld-linux-aarch64.so.1"
GLIBC_LIBDIR="$PREFIX/glibc/lib"
FREEBUFF_BINARY="$HOME/.config/manicode/freebuff"
# Shadow lib dir: contains a real libc.so symlink → libc.so.6 (ELF).
# The glibc package ships libc.so as a GNU ld linker script, which the
# runtime dynamic linker cannot process. Any dlopen("libc.so") call inside
# the freebuff binary will find the ELF symlink here instead of the script.
FREEBUFF_LIBS="$HOME/.freebuff-libs"

# ── Step 1: Update Termux packages ───────────────────────────────────────────
step "Step 1/5 — Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || warn "pkg update had warnings (non-fatal)."
ok "Package list updated."

# ── Step 2: Install Node.js ──────────────────────────────────────────────────
step "Step 2/5 — Checking Node.js (≥16 required)..."
if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version)
  if node -e "process.exit(parseInt(process.version.slice(1)) < 16 ? 1 : 0)" 2>/dev/null; then
    ok "Node.js $NODE_VER"
  else
    warn "Node.js $NODE_VER is too old. Upgrading..."
    pkg install -y nodejs-lts 2>/dev/null || pkg install -y nodejs 2>/dev/null
  fi
else
  info "Installing Node.js..."
  pkg install -y nodejs 2>/dev/null
  ok "Node.js $(node --version) installed."
fi
node --version >/dev/null 2>&1 || die "Node.js install failed. Run: pkg install nodejs"
npm  --version >/dev/null 2>&1 || die "npm not found. Run: pkg install nodejs"

# ── Step 3: Install Termux glibc layer ───────────────────────────────────────
step "Step 3/5 — Checking glibc layer..."
# The freebuff linux-arm64 binary is compiled for glibc, not Android bionic.
# The Termux glibc package provides ld-linux-aarch64.so.1 needed to run it.
if [[ -f "$GLIBC_LINKER" ]]; then
  ok "glibc layer present ($GLIBC_LINKER)"
else
  info "Installing Termux glibc layer..."
  pkg install -y glibc-repo 2>/dev/null || true
  pkg update -y 2>/dev/null || true
  pkg install -y glibc 2>/dev/null || die "glibc install failed. Run: pkg install glibc"
  [[ -f "$GLIBC_LINKER" ]] || die "glibc linker not found after install."
  ok "glibc layer installed."
fi

# ── Step 4: Install freebuff + download binary ────────────────────────────────
step "Step 4/5 — Installing freebuff..."

NPM_GLOBAL="$HOME/.npm-global"
mkdir -p "$NPM_GLOBAL"
npm config set prefix "$NPM_GLOBAL" 2>/dev/null || true
export PATH="$NPM_GLOBAL/bin:$PATH"

SHELL_RC="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
if ! grep -q 'npm-global' "$SHELL_RC" 2>/dev/null; then
  { echo ""; echo "# freebuff-mobile: npm global bin"; echo 'export PATH="$HOME/.npm-global/bin:$PATH"'; } >> "$SHELL_RC"
  info "Added npm global bin to $SHELL_RC"
fi

# Termux's Node.js reports os='android'; freebuff targets linux/darwin/win32.
# --force installs the package regardless — the linux-arm64 binary works
# correctly on Termux via the glibc layer installed above.
npm install -g freebuff --force 2>&1 | grep -v '^npm warn' | tail -3
ok "npm package installed."

# Remove the npm-global bin symlink — it points to the JS launcher (index.js)
# which cannot execute the glibc binary correctly on Termux. The glibc-aware
# launcher installed at $PREFIX/bin/freebuff in Step 5 replaces it.
rm -f "$NPM_GLOBAL/bin/freebuff"

# Trigger the freebuff launcher once to download the linux-arm64 native binary.
# FREEBUFF_BINARY_TARGET=linux-arm64 overrides the platform resolution so the
# correct binary is fetched rather than an unsupported 'android-arm64' target.
if [[ ! -f "$FREEBUFF_BINARY" ]]; then
  info "Downloading freebuff binary (~130 MB)..."
  FREEBUFF_PKG=$(npm root -g 2>/dev/null)/freebuff
  FREEBUFF_BINARY_TARGET=linux-arm64 node "$FREEBUFF_PKG/index.js" --version 2>&1 \
    | grep -Ev '^$|^Downloading' | head -5 || true
  for i in $(seq 1 12); do
    [[ -f "$FREEBUFF_BINARY" ]] && break
    sleep 5
    info "Waiting for download... ($i/12)"
  done
fi

if [[ -f "$FREEBUFF_BINARY" ]]; then
  chmod +x "$FREEBUFF_BINARY"
  ok "Binary ready: $(ls -lh "$FREEBUFF_BINARY" | awk '{print $5, $NF}')"
else
  die "Binary not found at $FREEBUFF_BINARY. Check your internet connection and retry."
fi

FREEBUFF_VER=$("$GLIBC_LINKER" --library-path "$FREEBUFF_LIBS:$GLIBC_LIBDIR" "$FREEBUFF_BINARY" --version 2>/dev/null || echo "unknown")
ok "freebuff version: $FREEBUFF_VER"

# ── Step 5: Install launcher ─────────────────────────────────────────────────
step "Step 5/5 — Installing freebuff launcher..."

# Create shadow lib dir with a real libc.so → libc.so.6 symlink.
# The glibc package's libc.so is a GNU ld linker script (text), not an ELF.
# The runtime dynamic linker rejects it when freebuff calls dlopen("libc.so").
# Placing an ELF symlink in this directory ahead of the system glibc path
# ensures dlopen finds the real shared library instead of the script.
mkdir -p "$FREEBUFF_LIBS"
ln -sf "$GLIBC_LIBDIR/libc.so.6" "$FREEBUFF_LIBS/libc.so"
ok "libc.so shadow symlink → libc.so.6"

LAUNCHER="$PREFIX/bin/freebuff"
cat > "$LAUNCHER" <<LAUNCH
#!/data/data/com.termux/files/usr/bin/bash
# freebuff — Termux launcher for freebuff AI coding agent
FREEBUFF_BIN="\$HOME/.config/manicode/freebuff"
FREEBUFF_LIBS="\$HOME/.freebuff-libs"
GLIBC_LINKER="${GLIBC_LINKER}"
GLIBC_LIBDIR="${GLIBC_LIBDIR}"
if [[ ! -f "\$FREEBUFF_BIN" ]]; then
  echo "[!] freebuff binary not found. Run: bash \$HOME/freebuff-mobile/install.sh"
  exit 1
fi
export TERM="\${TERM:-xterm-256color}"
export COLORTERM="\${COLORTERM:-truecolor}"
exec "\$GLIBC_LINKER" --library-path "\$FREEBUFF_LIBS:\$GLIBC_LIBDIR" "\$FREEBUFF_BIN" "\$@"
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
echo -e " ${YEL}Update:${NC}"
echo -e "   ${GRN}npm install -g freebuff@latest --force${NC}"
echo ""
echo -e " ${BLU}Docs   → https://github.com/remonsec/freebuff-mobile${NC}"
echo -e " ${BLU}Upstream → https://freebuff.com${NC}"
echo ""
