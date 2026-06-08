# System Maintenance & Recovery Guide

This guide documents the specific manual configurations, environment variables, and hidden settings that make this ARM64 Android development environment work. Use this to restore the environment if you ever need to reinstall.

## 1. Environment Variables (`~/.bashrc`)

Critical paths for the custom ARM64 SDK and NDK. Add these to your `~/.bashrc`:

```bash
# Android SDK & NDK Paths
export ANDROID_SDK_ROOT=/opt/android-sdk-custom/android-sdk
export ANDROID_HOME=/opt/android-sdk-custom/android-sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.0.12077973
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME

# Path Priority
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
export PATH=$ANDROID_SDK_ROOT/build-tools/36.1.0:$PATH
export PATH=/data/data/com.termux/files/usr/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Tool Init
eval "$(zoxide init bash)"
source ~/.local/bin/bashmarks.sh
```

---

## 2. Git & Security Configuration

### Git Global Settings
These prevent `safe.directory` errors in shared storage and enable SSH-based commit signing.

```bash
git config --global user.name "estiaksoyeb"
git config --global user.email "estiakahamed122@gmail.com"
git config --global pull.rebase true
git config --global pull.ff only
git config --global rebase.autostash true

# Large Repo Support
git config --global http.postbuffer 524288000

# GPG/SSH Signing
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedsignersfile /root/.config/git/allowed_signers
```

### SSH Keys (`~/.ssh`)
Ensure your `id_ed25519` key is backed up. The `~/.ssh/config` should point to your keys appropriately:
*   `id_ed25519`: Primary key (GitHub/Commit signing).
*   `id_ed25519_second`: Backup/Secondary key.

---

## 3. Toolchain Versions

The following versions are confirmed stable in this environment:

| Tool | Version |
| :--- | :--- |
| **OpenJDK** | 17.0.18 |
| **Node.js** | 20.20.2 |
| **Neovim** | 0.12.2 |
| **Git** | 2.43.0 |
| **Python** | 3.12.3 |
| **NDK** | 27.0.12077973 |

---

## 4. Storage & Permissions (Headache Prevention)

### The `safe.directory` Problem
When working in `/sdcard` or shared folders on Android, Git will complain about ownership. 
**Solution:** Run this for your project directories:
```bash
git config --global --add safe.directory /sdcard/Projects/YourProject
```

### Termux Binaries in Chroot (and Path Conflicts)
To use Termux binaries (like `termux-open` or `git` from Termux) inside the chroot, the path `/data/data/com.termux/files/usr/bin` is typically added to your `$PATH`. 

However, because this path is usually prepended, **Termux binaries take precedence over chroot binaries** of the same name. This can lead to "stuck" package versions if you install the same tool globally in both environments (e.g. Node/NPM packages).

#### 🔍 Example Conflict: Outdated Global Packages
If you install a package like `opencode-ai` inside both environments, you might run `npm i -g opencode-ai` in the chroot to update it, but executing `opencode` still runs the older Termux version.

**How to Diagnose:**
1. Check all paths of the command:
   ```bash
   type -a opencode
   # Output:
   # opencode is /data/data/com.termux/files/usr/bin/opencode  <-- Termux (prioritized)
   # opencode is /usr/bin/opencode                            <-- Chroot
   ```
2. Check the version of each location directly:
   ```bash
   /data/data/com.termux/files/usr/bin/opencode --version
   /usr/bin/opencode --version
   ```

**How to Fix:**
1. Delete the overriding Termux binary symlink and node module:
   ```bash
   rm /data/data/com.termux/files/usr/bin/opencode
   rm -rf /data/data/com.termux/files/usr/lib/node_modules/opencode-ai
   ```
2. **Clear the Shell Cache (Crucial):** Bash caches command paths in a hash table. After deleting the file, running the command immediately might cause a `No such file or directory` error. Clear the cache:
   ```bash
   hash -r
   ```

---


## 5. Recovery Checklist
1. Re-install the Ubuntu/Debian chroot.
2. Run `setup-gemini.sh` and `install.sh`.
3. Restore `~/.ssh/` and `~/.bashrc`.
4. Apply Git `safe.directory` for all active project paths.
5. Install **zoxide** and **bashmarks** via their respective installers.
