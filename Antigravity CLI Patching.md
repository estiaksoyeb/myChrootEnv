# Antigravity CLI Compatibility & Patching Guide

> [!IMPORTANT]
> The official Google Antigravity CLI is designed for standard x86_64 or ARM64 Linux servers. When running on Android (whether in native Termux or inside an **Ubuntu Chroot**), it will crash immediately with memory allocation errors due to kernel-level architecture differences. This guide documents how to patch, run, and maintain the CLI in your environment without requiring AI coding assistance.

---

## 1. The Core Problem: The Memory "Skyscraper" Mismatch

The Antigravity CLI is built using Google's **TCMalloc** (a custom memory allocator). 
* **Standard Linux Servers:** Assume a **48-bit Virtual Address (VA) space**. Think of this as a skyscraper with **48 floors**. The CLI regularly requests memory locations on high floors (e.g., above the 39th floor).
* **Android Kernels (and Chroots):** Most ARM64 Android kernels are limited to a **39-bit Virtual Address space** (a skyscraper with only **39 floors**).
* **The Crash:** When the unmodified CLI starts up, it asks the system kernel for a memory address on a floor that physically does not exist in the Android building. The kernel rejects the request, and the CLI crashes immediately with:
  ```text
  FATAL ERROR: Out of memory trying to allocate internal tcmalloc data
  MmapAligned() failed - unable to allocate with tag
  ```

---

## 2. How the Patching Architecture Works

To make the CLI run perfectly inside your Ubuntu Chroot, the project uses a two-part setup: **Binary Surgery (Build Time)** and **Dynamic Interception (Runtime)**.

### Part A: Binary Surgery (Build Time)
* **Script:** `build.sh` (inside the `antigravity-cli-termux` project)
* **What it does:** Downloads the raw official binary from Google and runs a Python script that acts like a digital surgeon. It searches for specific hex byte patterns representing assembly instructions (like `ubfx` and `mmap`) that request high-floor memory addresses and modifies them to safe, low-floor equivalents.
* **Output:** A modified binary named `bin/agy.va39`.

### Part B: The Smart Bootstrapper & Chaperone
* **Files:** `lib/agy_helper.c` (compiled into `bin/agy`)
* **What it does:** Standard chroots use standard Linux path structures, whereas Termux uses Android-specific paths. The bootstrapper checks the filesystem at runtime:
  * If it detects it is running inside an **Ubuntu Chroot**, it automatically configures the application to use standard system paths (e.g., `/lib/ld-linux-aarch64.so.1` for loading and `/etc/ssl/certs/ca-certificates.crt` for web security).
  * It clears conflicting Android-specific variables (like `LD_PRELOAD`) that would crash the standard Linux loader.

---

## 3. The Chroot Savior: Dynamic Library Preloading

In an Ubuntu Chroot, simply editing the binary is not always enough, as strict Linux libraries can bypass static edits. The definitive solution is **Runtime Library Interposition** (preloading).

### The Safety Net Guard
* **Source:** `lib/mmap_va39_fix.c` (compiled to `lib/libmmap_va39_fix.so`)
* **How it works:** This is a tiny C library that acts like a translator sitting between the app and the kernel. 
  1. The chaperone (`bin/agy`) automatically preloads this library when starting the app in Ubuntu.
  2. Every time the CLI requests memory via the system `mmap` call (e.g., *"give me a room on the 48th floor"*), our guard intercepts it.
  3. If the requested floor is higher than the 39th floor boundary, the guard clears the target address and says, *"Give it any free room on a lower floor instead."*
  4. The kernel returns a safe address, and the app runs flawlessly.

---

## 4. Maintenance Survival Guide (No AI Required)

If Gemini CLI is shut down or unavailable, you can easily maintain and keep the CLI updated using standard terminal tools.

### Scenario A: Google Releases an Update
If Google releases a new version of the Antigravity CLI, you do not need to rewrite the code. The build scripts are already fully automated.
1. Navigate to your patched repository:
   ```bash
   cd ~/Projects/antigravity-cli-termux
   ```
2. Run the automated builder:
   ```bash
   ./build.sh
   ```
   *This script will query Google's release API, download the raw arm64 binary, run the Python editor, compile the chaperone, and package a fresh, working version.*

### Scenario B: The App Crashes (Debugging with `strace`)
If a future update breaks the byte-editing patterns and causes a memory crash, you can diagnose it using **`strace`** (System Call Tracer):
1. Install `strace` in your Chroot:
   ```bash
   sudo apt install strace
   ```
2. Run the CLI with the tracer:
   ```bash
   strace bin/agy
   ```
3. Read the output. Look at the last lines before the crash. If you see a line containing `mmap` returning an error (`-1 EINVAL` or `ENOMEM`) with a huge address (e.g. `0x2f4c00000000`), you immediately know: **TCMalloc has changed its initialization parameters, and it is requesting a memory floor above the 39-bit limit.**

### Scenario C: Finding the New "Magic Numbers"
If the byte-patching Python script fails because Google changed the compiled code:
1. **Don't Panic:** You do not have to find the bytes yourself.
2. Check the open-source community repositories for similar issues:
   * [hjotha/termux-tcmalloc-patch](https://github.com/hjotha)
   * [Brajesh2022 compatibility patches](https://github.com/Brajesh2022)
3. Once the community finds the new byte-offsets for the latest version, open `build.sh`, locate the `word_rewrites` dictionary inside the Python block, and update the values accordingly.

---

## 5. Summary Checklist of Key Skills to Master

To ensure you can maintain this setup forever:
* [ ] **Basic Bash scripting:** Understand how to modify and execute shell scripts.
* [ ] **`strace` usage:** Know how to run a program under `strace` to identify failing system calls.
* [ ] **LD_PRELOAD Concept:** Understand how shared libraries (`.so` files) can intercept system functions dynamically.
* [ ] **ARM64 Assembly Basics:** Know what `ubfx` (unsigned bitfield extract) and `mmap` do at a high level.
