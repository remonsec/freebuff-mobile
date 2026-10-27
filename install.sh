#!/usr/bin/env bash
# =============================================================================
# freebuff-mobile — Install Freebuff AI Coding Agent in Termux (Android ARM64)
# Author  : remonsec <https://github.com/remonsec>
# Repo    : https://github.com/remonsec/freebuff-mobile
# License : MIT
#
# Freebuff is the free, ad-supported AI coding agent from Codebuff.
#   • Runs natively in Termux — no proot, no root, no GUI required
#   • Supports Linux arm64 out of the box (npm package)
#   • Uses open-source models: DeepSeek, GLM, MiMo, Solar, and more
#   • Works with any editor: VS Code, Cursor, Neovim, etc.
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
[[ "$(uname -m)" == "aarch64" ]] || {
  warn "Not aarch64, but proceeding anyway (may work on other arches)."
}
[[ -d "/data/data/com.termux" ]] || die "Must be run inside Termux."

# ── Step 1: Update Termux packages ────────────────────────────────────────────
step "Step 1/4 — Updating Termux package list..."
pkg update -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || warn "pkg update had warnings (non-fatal)"
ok "Package list updated."

# ── Step 2: Install Node.js ───────────────────────────────────────────────────
step "Step 2/4 — Checking Node.js..."
if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version)
  # Check major version >= 16
  NODE_MAJOR=$(node -e "process.exit(parseInt(process.version.slice(1)) < 16 ? 1 : 0)" 2>/dev/null && echo ok || echo old)
  if [[ "$NODE_MAJOR" == "old" ]]; then
    warn "Node.js $NODE_VER is too old (need ≥16). Upgrading..."
    pkg install -y nodejs-lts 2>/dev/null || pkg install -y nodejs 2>/dev/null
  else
    ok "Node.js $NODE_VER already installed ✓"
  fi
else
  info "Node.js not found. Installing..."
  pkg install -y nodejs 2>/dev/null
  ok "Node.js $(node --version) installed."
fi

# Verify
node --version >/dev/null 2>&1 || die "Node.js install failed. Run: pkg install nodejs"
npm --version  >/dev/null 2>&1 || die "npm not found. Run: pkg install nodejs"

# ── Step 3: Install freebuff globally ─────────────────────────────────────────
step "Step 3/4 — Installing freebuff via npm..."

# Configure npm global dir inside Termux prefix (avoids permission issues)
NPM_GLOBAL="$HOME/.npm-global"
mkdir -p "$NPM_GLOBAL"
npm config set prefix "$NPM_GLOBAL" 2>/dev/null || true

# Ensure PATH includes npm global bin
SHELL_RC="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q 'npm-global' "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo '# freebuff-mobile: npm global bin' >> "$SHELL_RC"
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_RC"
  info "Added npm global bin to $SHELL_RC"
fi
export PATH="$NPM_GLOBAL/bin:$PATH"

# Install freebuff
npm install -g freebuff 2>&1 | tail -5

# Verify install
if command -v freebuff >/dev/null 2>&1; then
  FB_VER=$(freebuff --version 2>/dev/null || echo "installed")
  ok "freebuff $FB_VER installed at $(command -v freebuff)"
elif [[ -f "$NPM_GLOBAL/bin/freebuff" ]]; then
  ok "freebuff installed at $NPM_GLOBAL/bin/freebuff"
  warn "Run: source ~/.bashrc  (to add to PATH in current session)"
else
  die "freebuff install failed. Check npm output above."
fi

# ── Step 4: Create shell alias + quick-start helper ───────────────────────────
step "Step 4/4 — Setting up shell integration..."

# Write a Termux-aware wrapper so freebuff always runs in the right env
WRAPPER="$PREFIX/bin/freebuff-termux"
cat > "$WRAPPER" <<'WRAP'
#!/usr/bin/env bash
# freebuff-termux — Termux-aware freebuff launcher
# Ensures npm global bin is in PATH before launching
export PATH="$HOME/.npm-global/bin:$PATH"

# Workaround: Termux's terminal may not support raw mode fully;
# TERM and COLORTERM hints help TUI rendering
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"

exec freebuff "$@"
WRAP
chmod +x "$WRAPPER"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN} ✓  freebuff is ready on Termux!${NC}"
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " ${YEL}First, reload your shell:${NC}"
echo -e "   ${GRN}source ~/.bashrc${NC}"
echo ""
echo -e " ${YEL}Navigate to a project and launch:${NC}"
echo -e "   ${GRN}cd ~/my-project${NC}"
echo -e "   ${GRN}freebuff${NC}"
echo ""
echo -e " ${YEL}Or use the Termux wrapper (always works):${NC}"
echo -e "   ${GRN}freebuff-termux${NC}"
echo ""
echo -e " ${YEL}Update freebuff anytime:${NC}"
echo -e "   ${GRN}npm install -g freebuff@latest${NC}"
echo ""
echo -e " ${BLU}Docs → https://github.com/remonsec/freebuff-mobile${NC}"
echo -e " ${BLU}Upstream → https://freebuff.com${NC}"
echo ""
