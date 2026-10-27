<div align="center">

<h1>📱 freebuff-mobile</h1>

<p><strong>Run <a href="https://freebuff.com">Freebuff</a> — the world's strongest free AI coding agent — inside Termux on Android</strong></p>

<p>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20ARM64-green?logo=android">
  <img alt="Node.js" src="https://img.shields.io/badge/node-%E2%89%A516-brightgreen?logo=node.js">
  <img alt="npm" src="https://img.shields.io/badge/npm-freebuff-CB3837?logo=npm">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue">
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
> Freebuff is a terminal-first AI coding agent. This installer handles Android/Termux compatibility automatically — including the glibc layer required for the native binary. **No root, no GUI, no proot required.**

---

## 🤖 What is Freebuff?

[Freebuff](https://freebuff.com) is the **free, ad-supported version of [Codebuff](https://codebuff.com)** — a terminal-first AI coding agent that autonomously reads, writes, and refactors code across your entire project using natural language.

| Feature | Details |
|---|---|
| **Multi-agent architecture** | File picker → Planner → Editor → Reviewer agents work in concert |
| **Free models** | DeepSeek Flash, GLM Flash, MiMo, Solar, and more — no API key needed |
| **Autonomous execution** | Reads/writes files, runs commands, installs packages, verifies tests |
| **Editor agnostic** | Works alongside VS Code, Cursor, Neovim, nano — any editor |
| **No subscription** | Ad-supported; unlimited code generation |
| **Open source** | MIT license — [npm package](https://www.npmjs.com/package/freebuff) |

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| **Device** | Android 7+ (ARM64 / aarch64) |
| **App** | [Termux](https://f-droid.org/packages/com.termux/) from **F-Droid** (not Play Store) |
| **Node.js** | ≥ 16 (installed automatically by `install.sh`) |
| **RAM** | ≥ 1 GB free (2 GB+ recommended) |
| **Storage** | ~500 MB (Node.js + npm package + native binary) |
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

One-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/remonsec/freebuff-mobile/main/install.sh)
```

After install:

```bash
cd ~/your-project
freebuff
```

---

## ⚙️ How it Works

```
install.sh
 ├─ 1. pkg update
 ├─ 2. pkg install nodejs              ← Termux arm64 Node.js (v16+)
 ├─ 3. pkg install glibc               ← glibc layer for linux-arm64 ELF binary
 ├─ 4. npm install -g freebuff --force ← npm package + binary download (~130 MB)
 └─ 5. $PREFIX/bin/freebuff            ← launcher invokes binary via glibc linker
```

### Why glibc is needed

Freebuff's linux-arm64 binary is compiled for glibc (`ld-linux-aarch64.so.1`). Termux uses Android's bionic libc, which cannot execute this binary directly. The [Termux glibc package](https://github.com/termux/termux-packages/tree/master/packages/glibc) provides the required dynamic linker. The `freebuff` launcher installed by this script handles invocation transparently.

```
Android ARM64 hardware
  └─ Termux (bionic libc)
       ├─ Node.js (arm64)      →  npm install -g freebuff --force
       ├─ glibc layer          →  $PREFIX/glibc/lib/ld-linux-aarch64.so.1
       └─ $PREFIX/bin/freebuff →  exec glibc-linker ~/.config/manicode/freebuff
```

---

## 🛠 Usage

### Basic workflow

```bash
cd ~/projects/my-app
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
freebuff              # interactive agent mode
freebuff --version    # show version
freebuff --help       # all options
```

### Project context file

Create a `knowledge.md` at your repo root to give Freebuff permanent project context:

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
| `~/.config/manicode/freebuff` | freebuff linux-arm64 native binary (~130 MB) |
| `~/.npm-global/lib/node_modules/freebuff/` | npm package (JS launcher) |
| `$PREFIX/bin/freebuff` | Termux launcher (glibc-aware) |
| `$PREFIX/glibc/lib/ld-linux-aarch64.so.1` | glibc dynamic linker |
| `~/.bashrc` / `~/.zshrc` | PATH entry for npm global bin |

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

### `freebuff: command not found`

```bash
echo $PATH   # $PREFIX/bin must be present
ls $PREFIX/bin/freebuff
```

### `cannot execute: required file not found`

The glibc layer may not be installed:

```bash
pkg install glibc
bash ~/freebuff-mobile/install.sh
```

### TUI rendering issues (broken characters)

```bash
export TERM=xterm-256color
export COLORTERM=truecolor
freebuff
```

### Network error during AI inference

Freebuff uses cloud-hosted free models. Verify connectivity:

```bash
curl -I https://freebuff.com
```

---

## 📊 Freebuff vs Alternatives on Termux

| Tool | Install | GUI Needed | Free Tier |
|---|---|---|---|
| **freebuff** | `install.sh` (npm + glibc) | No | ✅ Fully free |
| Cursor IDE | `install.sh` (proot + AppImage) | Yes | ❌ Subscription |
| Claude Code | `npm install -g @anthropic-ai/claude-code` | No | ❌ API cost |
| Aider | `pip install aider-chat` | No | ⚠️ BYO API key |

---

## 📜 License

MIT © [remonsec](https://github.com/remonsec)

---

<div align="center">

Made for hackers who code on phones 📱⚡

**[freebuff.com](https://freebuff.com)** • **[@remonsec](https://twitter.com/remonsec)** • **[GitHub](https://github.com/remonsec)**

</div>
