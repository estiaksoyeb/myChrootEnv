# Tmux Session Persistence Setup & Usage Guide

> [!NOTE]
> This guide details how to keep your **tmux** session layout, open tabs/windows, split panes, working directories, terminal pane contents, and running tools saved permanently on disk so that your exact environment is automatically restored even after a sudden power loss or system reboot.

---

## 🖥️ Overview

When working in a chroot/proot environment on mobile or Linux servers, unexpected power disconnections or process kills normally erase running tmux sessions.

Using **`tmux-resurrect`** and **`tmux-continuum`**, tmux continuously records session state in the background. On system reboot or terminal reconnection, tmux automatically reads the save state and restores your workspace completely.

---

## 🛠️ How The Setup Was Implemented

### 1. Installed Required Plugins

The setup relies on two core plugins inside `~/.tmux/plugins/`:

- **`tmux-resurrect`**: Core engine that serializes tmux state (windows, panes, layouts, directories, scrollback, and processes) into text files located at `~/.local/share/tmux/resurrect/`.
- **`tmux-continuum`**: Background worker that periodically calls `tmux-resurrect` every 60 minutes (1 hour) and triggers auto-restore when the tmux server starts up.

Command used to clone `tmux-continuum` (if not already installed via TPM):
```bash
git clone https://github.com/tmux-plugins/tmux-continuum ~/.tmux/plugins/tmux-continuum
```

---

### 2. Configured `~/.tmux.conf`

The following configuration was added to `/root/.tmux.conf`:

```tmux
# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Automatic Save & Restore (tmux-continuum)
set -g @continuum-restore 'on'
set -g @continuum-save-interval '60'

# Resurrect Settings
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-processes 'agy vim nvim node python python3 btop htop'

# Manual resurrect keybindings
bind -n PageUp copy-mode -u
bind-key S run-shell '~/.tmux/plugins/tmux-resurrect/scripts/save.sh'
bind-key R run-shell '~/.tmux/plugins/tmux-resurrect/scripts/restore.sh'

# Load plugin scripts
run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux
run-shell ~/.tmux/plugins/tmux-continuum/continuum.tmux

# Initialize TPM
run '~/.tmux/plugins/tpm/tpm'
```

Key Settings Explained:
- `@continuum-save-interval '5'`: Saves environment state every 5 minutes automatically.
- `@continuum-restore 'on'`: Automatically triggers session restoration whenever the tmux server starts.
- `@resurrect-capture-pane-contents 'on'`: Saves scrollback buffers so terminal output text isn't lost.
- `@resurrect-processes '...'`: Defines running commands to resurrect automatically.

---

### 3. Reloaded Configuration Live

To apply the configuration into the active tmux session without restarting:
```bash
tmux source-file ~/.tmux.conf
```

---

## 🚀 How To Use It

### Automatic Operation (Zero Maintenance)
- **Auto-Saving:** Runs silently in the status loop every 5 minutes.
- **Auto-Restoring:** If your power unplugs or the machine restarts:
  1. Turn system back on and log in.
  2. Start tmux (`tmux` or log in via SSH).
  3. `tmux-continuum` immediately detects tmux startup and restores your last saved session (windows, tabs, splits, directories, and terminal buffer).

---

### Manual Commands & Keybindings

You can also manually save or restore your setup at any time:

| Action | Shortcut / Command | Description |
| :--- | :--- | :--- |
| **Manual Save** | `Prefix` + `S` (`Ctrl+B` then `S`) | Immediately saves current tmux state to disk |
| **Manual Restore** | `Prefix` + `R` (`Ctrl+B` then `R`) | Instantly restores the last saved state from disk |
| **CLI Save** | `tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh` | Trigger save from bash terminal |
| **CLI Restore** | `tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh` | Trigger restore from bash terminal |

---

## 🔍 Verification & Troubleshooting

### Check Continuum Status
Run this inside tmux to verify continuum status and save timestamps:
```bash
tmux show-options -g | grep continuum
```
You should see:
```text
@continuum-restore on
@continuum-save-interval 5
@continuum-save-last-timestamp <timestamp>
```

### Save Location
All state files are preserved under:
```bash
ls -la ~/.local/share/tmux/resurrect/
```
- `last` points to the most recent save file.
- `pane_contents.tar.gz` holds terminal buffer history.

---

## ⚡ Auto-Attach on Login (Recommended)

To ensure tmux launches automatically upon logging into your shell, check your `~/.bashrc`:
```bash
# Auto-attach to tmux on SSH login
if [ -n "$SSH_CONNECTION" ] && command -v tmux >/dev/null; then
    [ -z "$TMUX" ] && exec tmux new-session -A -s main
fi
```
This ensures your session is attached immediately whenever you log back in after a reboot.
