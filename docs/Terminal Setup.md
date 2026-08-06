# Terminal Prompt & Auto-suggestions Setup

A guide to setting up a beautiful, context-aware prompt (**Starship**) and Fish-like auto-suggestions (**ble.sh**) in a bash environment, specifically tailored for Termux/chroot environments.

## 1. Starship Prompt (Pastel Powerline)

Starship is a blazing-fast, cross-shell prompt written in Rust. We use a customized "Pastel Powerline" layout that looks beautiful but stays clean by hiding unnecessary language indicators.

### Installation
Run the official installation script:
```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

### Configuration
Starship requires a **Nerd Font** (like FiraCode Nerd Font) installed in your terminal emulator to render the Powerline arrows (``, ``) correctly.

Create the configuration file at `~/.config/starship.toml` and apply the Pastel Powerline preset, but with specific overrides to keep it clean on a single line:

```bash
# Apply the official Pastel Powerline preset
starship preset pastel-powerline -o ~/.config/starship.toml
```

Append the following overrides to the end of `~/.config/starship.toml` to hide certain modules (like Java, Python, GCC) if you want a minimal look:
```toml
# -----------------
# User overrides
# -----------------
[java]
disabled = true

[python]
disabled = true

[gcc]
disabled = true
```

---

## 2. Bash Line Editor (ble.sh)

Since `bash` lacks built-in auto-suggestions (like `fish` or `zsh-autosuggestions`), we use `ble.sh` to overhaul the bash line editor. It provides:
- **Ghost text auto-suggestions** (predicts what you'll type based on history; accept with `Right Arrow`).
- **Real-time syntax highlighting**.

### Installation (Pre-requisites: `make`, `gawk`)
```bash
sudo apt install -y make gawk
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local
rm -rf ble.sh
```

---

## 3. Bashrc Integration & Chroot Fixes

In a chroot/proot environment (like AndroidIDE/Termux), standard Linux login variables like `$USER` and `$LANG` might not be automatically populated when logging in as root. `ble.sh` will throw "insane environment" or "broken locale" warnings if these are missing.

To fix this, append the following to the very end of your `~/.bashrc`:

```bash
# Initialize starship prompt
eval "$(starship init bash)"

# Fix missing environment variables for ble.sh in Termux/chroot environments
export USER=${USER:-$(id -un)}
# Android typically uses C.UTF-8 instead of en_US.UTF-8
export LANG=${LANG:-C.UTF-8}

# Initialize ble.sh (auto-suggestions and syntax highlighting)
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh
```

Restart your terminal or run `source ~/.bashrc` for the changes to take effect.
