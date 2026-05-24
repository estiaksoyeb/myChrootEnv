# myChrootEnv

> [!IMPORTANT]
> This repository is specifically designed for **proot** and **chroot** environments (e.g., Ubuntu, Debian, or Kali inside Termux/AndroidIDE). It will **NOT** work in **native Termux**. Native Termux users should instead use the `tur-repo` or standard package managers which handle these architecture issues natively.

A specialized environment setup for **Android development** and **AI-assisted coding** on ARM64 Linux systems.

This repository provides a hardened workflow to build modern Android apps (AGP 8.x) and native C/C++ code directly on an Android phone, bypassing the common architecture mismatch issues that plague mobile-based development.

## The Real Problem
Android Gradle Plugin (AGP) and the official NDK often download or include `x86_64` binaries (like `aapt2`, `clang`, or `make`). On **ARM64** Android devices, these binaries fail with errors like `Syntax error` or `Exec format error`. 

**myChrootEnv** solves this by:
1. Providing an **ARM64-native Android SDK** (via `android-sdk-custom`).
2. Implementing a **Global AAPT2 Override** in Gradle.
3. Offering a **Symlink & Patch** strategy for the NDK.

---

## Quick Installation

### 1. Setup Gemini CLI and Node.js
Install Node.js 20 and the Gemini CLI for AI-assisted development:
```bash
curl -sSL https://raw.githubusercontent.com/easoyeb/myChrootEnv/main/setup-gemini.sh | bash
```

### 2. Install ARM64 Android SDK
Download the custom ARM64 SDK and configure your environment:
```bash
curl -sSL https://raw.githubusercontent.com/easoyeb/myChrootEnv/main/install.sh | bash
```

---

## Detailed Documentation & Guides

For a deep dive into how these setups work and how to troubleshoot them, refer to these guides:

- 📱 **[Building Android Apps (AGP 8.x)](./Build%20with%20Termux.md)**: Detailed breakdown of the ARM64 SDK, AAPT2 overrides, and Gradle optimizations.
- 💙 **[Flutter Setup](./Flutter%20Setup.md)**: Integrating Flutter with the ARM64-native SDK and fixing `cmdline-tools` path issues.
- ⚙️ **[NDK & Native Code Setup](./NDK%20Setup.md)**: How to patch the Android NDK to use native ARM64 toolchains (`clang`, `make`, `ninja`) and fix linker errors.
- ⌨️ **[Kotlin LSP Setup (Neovim)](./Kotlin%20LSP%20Setup.md)**: Working setup for Kotlin Language Server with Neovim 0.11+ in a chroot environment.
- 🛠️ **[Termux Configuration](./termux/termux.properties)**: Optimized `termux.properties` with specialized Git and Vim macros.

---

## Key Features
- **Custom ARM64 Android SDK:** Uses [android-sdk-custom](https://github.com/HomuHomu833/android-sdk-custom) (Zig + musl) for native performance.
- **Git-Optimized Extra Keys:** Custom Termux keyboard rows with macros for `git status`, `add`, `commit`, `push`, and Vim quick-exit (`:q`, `:wq`).
- **Flutter Ready:** Pre-configured for Flutter development on ARM64.
- **AAPT2 Global Override:** Automatically configures `~/.gradle/gradle.properties` to use local ARM64 binaries.
- **Optimized for Mobile:** Pre-configured Gradle flags (in-process compilation) to manage RAM efficiently on Android.
- **AI-Ready:** Integrated Gemini CLI for terminal-based AI assistance.

## Usage
After installation, you can build your projects directly from the CLI:
```bash
./gradlew assembleDebug
```

## Repository
`git@github.com:easoyeb/myChrootEnv.git`

## License
MIT
