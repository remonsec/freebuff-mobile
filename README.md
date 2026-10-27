<div align="center">

<h1>📱 freebuff-mobile</h1>

<p><strong>Run <a href="https://freebuff.com">Freebuff</a> — the world's strongest free AI coding agent — inside Termux on Android</strong></p>

<p>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20ARM64-green?logo=android">
  <img alt="Node.js" src="https://img.shields.io/badge/node-%E2%89%A516-brightgreen?logo=node.js">
  <img alt="npm" src="https://img.shields.io/badge/npm-freebuff-CB3837?logo=npm">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue">
  <img alt="Freebuff" src="https://img.shields.io/badge/freebuff-v0.2.34-orange">
  <img alt="Author" src="https://img.shields.io/badge/author-remonsec-purple">
</p>

<p>
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-what-is-freebuff">What is Freebuff</a> •
  <a href="#-requirements">Requirements</a> •
  <a href="#-how-it-works">How it Works</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

</div>

---

> [!NOTE]
> Unlike GUI-heavy tools, **Freebuff is a native terminal CLI** — it installs directly in Termux via `npm` with **no proot, no root, and no X11 display server required**. It officially supports `linux/arm64`, making Android the perfect platform.

---

## 🤖 What is Freebuff?

[Freebuff](https://freebuff.com) is the **free, ad-supported version of [Codebuff](https://codebuff.com)** — a terminal-first AI coding agent that autonomously reads, writes, and refactors code across your entire project using natural language.

| Feature | Details |
|---|---|
| **Multi-agent architecture** | File picker → Planner → Editor → Reviewer agents work in concert |
| **Free models** | DeepSeek Flash, GLM Flash, MiMo, Solar, and more — no API key needed |
| **Autonomous execution** | Reads/writes files, runs commands, installs packages, verifies tests |
| **Editor agnostic** | Works with VS Code, Cursor, Neovim, nano — any editor |
| **No subscription** | Ad-supported; unlimited code generation |
| **Open source** | MIT license, [npm package](https://www.npmjs.com/package/freebuff) |

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| **Device** | Android 7+ (ARM64 / aarch64) |
| **App** | [Termux](https://f-droid.org/packages/com.termux/) from **F-Droid** (not Play Store) |
| **Node.js** | ≥ 16 (installed automatically by `install.sh`) |
| **RAM** | ≥ 1 GB free (2 GB+ recommended) |
| **Storage** | ~200 MB for Node.js + freebuff |
| **Network** | Required for first-time install and AI inference |

> [!IMPORTANT]
> Use the **F-Droid** version of Termux. The Play Store build is outdated and breaks `pkg install`.

---

## ⚡ Quick Start

```bash
pkg update && pkg install -y wget curl
wget https://raw.githubusercontent.com/remonsec/freebuff-mobile/main/install.sh
bash install.sh
```

**One-liner:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/remonsec/freebuff-mobile/main/install.sh)
```

**After install:**

```bash
source ~/.bashrc          # reload PATH
cd ~/your-project
freebuff                  # launch the agent
```

---

## ⚙️ How it Works

Freebuff is distributed as a Node.js npm package that downloads a native binary at first launch:

```
install.sh
 ├─ 1. pkg update
 ├─ 2. pkg install nodejs          ← Termux arm64 Node.js (v16+)
 ├─ 3. pkg install glibc           ← Termux glibc layer (linker for ELF binary)
 ├─ 4. npm install -g freebuff --force   ← --force bypasses os='android' check
 ├─ 5. FREEBUFF_BINARY_TARGET=linux-arm64 (downloads ~49 MB binary)
 └─ 6. $PREFIX/bin/freebuff wrapper  ← runs binary via glibc linker
```

### Termux-specific issues (all handled automatically)

| Issue | Root Cause | Fix Applied |
|---|---|---|
| `npm error notsup: Actual os: android` | Termux Node.js reports `process.platform = 'android'` not `'linux'` | `npm install --force` |
| `cannot execute: required file not found` | freebuff binary is a **glibc ELF** (`/lib/ld-linux-aarch64.so.1`), not bionic | Run via Termux glibc linker |
| `spawn ENOENT` on first run | Launcher tries to start binary before env is set | `FREEBUFF_BINARY_TARGET=linux-arm64` pre-downloads binary |

```
Android ARM64 hardware
  └─ Termux (bionic libc)
       ├─ Node.js arm64  →  npm install -g freebuff --force
       ├─ glibc layer    →  $PREFIX/glibc/lib/ld-linux-aarch64.so.1
       └─ freebuff launcher ($PREFIX/bin/freebuff)
              └─ exec glibc-linker ~/.config/manicode/freebuff ← linux-arm64 ELF
```

---

## 🛠 Usage

### Basic workflow

```bash
# Navigate to your project
cd ~/projects/my-app

# Launch freebuff agent
freebuff
```

Type your request in natural language:

```
> Add input validation to the login endpoint
> Write unit tests for auth.js
> Refactor database.py to use async/await
> Fix the bug in line 42 of server.go
```

### CLI flags

```bash
freebuff                          # interactive agent mode
freebuff --version                # show version
freebuff --help                   # show all options
npm install -g freebuff@latest    # update to latest version
```

### Project context file

Create a `knowledge.md` in your repo root to give Freebuff permanent project context:

```markdown
# knowledge.md
This is a Python FastAPI backend.
Use SQLAlchemy ORM. Tests are in pytest.
Never use print(); use logging instead.
```

### Custom agents

```bash
# Inside a freebuff session:
/init    # generates .agents/ directory with TypeScript agent definitions
```

---

## 🗂 File Locations

| Path | Purpose |
|---|---|
| `~/.config/manicode/freebuff` | freebuff linux-arm64 ELF binary (~49 MB) |
| `~/.npm-global/lib/node_modules/freebuff/` | npm package (launcher JS) |
| `$PREFIX/bin/freebuff` | Termux launcher wrapper (glibc-aware) |
| `$PREFIX/glibc/lib/ld-linux-aarch64.so.1` | glibc dynamic linker |
| `~/.bashrc` / `~/.zshrc` | PATH update for npm global bin |

---

## 🔄 Updating

```bash
npm install -g freebuff@latest --force
freebuff --version
```

---

## 🗑 Uninstall

```bash
npm uninstall -g freebuff
rm $PREFIX/bin/freebuff
rm -rf ~/.config/manicode/freebuff ~/.config/manicode/freebuff-metadata.json
```

---

## 🐛 Troubleshooting

### `npm error notsup: Actual os: android`

Termux's Node.js reports `process.platform = 'android'` instead of `'linux'`.
The install script handles this with `--force`. If running manually:

```bash
npm install -g freebuff --force
```

### `cannot execute: required file not found`

The freebuff binary is a **glibc ELF**, not a bionic binary. It needs Termux's glibc layer:

```bash
pkg install glibc
# Then use the installed launcher which handles this automatically:
freebuff
```

### `freebuff: command not found`

```bash
echo $PATH   # ensure $PREFIX/bin is in PATH
# The launcher should be at:
ls -la $PREFIX/bin/freebuff
```

### TUI rendering glitches (broken characters)

```bash
export TERM=xterm-256color
export COLORTERM=truecolor
freebuff
```

### Network error during AI inference

Freebuff uses cloud-hosted free models. Check connectivity:

```bash
curl -I https://freebuff.com
```

---

## 📊 Freebuff vs Alternatives on Termux

| Tool | Termux Install | Root Needed | GUI Needed | Free Tier |
|---|---|---|---|---|
| **freebuff** | `npm install --force` + glibc layer | ✗ No | ✗ No | ✅ Fully free |
| Cursor IDE | proot + AppImage | ✗ No | ✅ Yes | ❌ Subscription |
| Claude Code | `npm install -g @anthropic-ai/claude-code` | ✗ No | ✗ No | ❌ API cost |
| GitHub Copilot CLI | npm | ✗ No | ✗ No | ❌ Subscription |
| Aider | `pip install aider-chat` | ✗ No | ✗ No | ⚠️ BYO API key |

---

## 📜 License

MIT © [remonsec](https://github.com/remonsec)

---

<div align="center">

Made for hackers who code on phones 📱⚡

**[freebuff.com](https://freebuff.com)** • **[@remonsec](https://twitter.com/remonsec)** • **[GitHub](https://github.com/remonsec)**

</div>
