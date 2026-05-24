# Kotlin LSP Setup for Neovim in Ubuntu Chroot

This guide outlines a working setup for Kotlin development using Neovim and the Kotlin Language Server.

## 1. Install Java

```bash
apt update
apt install openjdk-21-jdk unzip wget
```

**Verify:**
```bash
java --version
```

---

## 2. Install modern Neovim (0.11+)

Remove old package version if needed:
```bash
apt remove neovim
```

Download AppImage (ARM64):
```bash
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.appimage
chmod +x nvim-linux-arm64.appimage
mv nvim-linux-arm64.appimage /usr/local/bin/nvim
```

Refresh shell:
```bash
hash -r
```

**Verify:**
```bash
nvim --version
```
Must show 0.11+ or 0.12+.

---

## 3. Install Kotlin Language Server

Download:
```bash
wget https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip
unzip server.zip -d ~/kotlin-ls
```

Server binary path:
`/root/kotlin-ls/server/bin/kotlin-language-server`

---

## 4. Configure vim-plug

Edit or create `~/.config/nvim/init.vim`:
```bash
mkdir -p ~/.config/nvim
nvim ~/.config/nvim/init.vim
```

**Plugin section:**
```vim
syntax on
set termguicolors

call plug#begin()

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

call plug#end()
```

Install plugins:
Inside Neovim, run `:PlugInstall` or from shell:
```bash
nvim +PlugInstall +qall
```

---

## 5. Configure Kotlin LSP (Neovim 0.11+/0.12 API)

Add the following below `call plug#end()` in `~/.config/nvim/init.vim`:

```vim
lua << EOF
vim.lsp.config('kotlin_language_server', {
  cmd = { '/root/kotlin-ls/server/bin/kotlin-language-server' },
})

vim.lsp.enable('kotlin_language_server')
EOF
```

---

## 6. Usage

Open the project root to ensure the LSP detects the project context correctly:

```bash
cd ~/Projects/YourProject
nvim
```

Open a Kotlin file:
`:e app/src/main/kotlin/com/example/MainActivity.kt`

---

## 7. Verify LSP

Inside Neovim:

*   **Check health:** `:checkhealth vim.lsp`
*   **Check active clients:** `:lua print(vim.inspect(vim.lsp.get_clients()))`

Expected: `kotlin_language_server` should appear in the list of active clients.

---

## 8. Test Diagnostics

Insert an intentional error (e.g., type mismatch):
```kotlin
val x: Int = "hello"
```
You should see diagnostics/error highlighting.

---

## Mobile-Friendly UI Setup

On mobile screens, diagnostic inline messages (virtual text) take up valuable horizontal space and can make code hard to read.

### 1. Optimize Diagnostic Display

Add this to `~/.config/nvim/init.vim` to hide inline text but keep markers:

```vim
lua << EOF
vim.diagnostic.config({
  virtual_text = false, -- Disable long inline messages
  underline = true,    -- Keep code underlining
  signs = true,        -- Keep gutter markers
})
EOF
```

### 2. Read Diagnostics on Demand

Add keybindings to view full messages in a popup and navigate errors:

```vim
lua << EOF
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', 'gl', vim.diagnostic.open_float)
EOF
```

**Usage:**
*   **`gl`**: Show full diagnostic message in a popup (float).
*   **`]d`**: Jump to next diagnostic.
*   **`[d`**: Jump to previous diagnostic.

### 3. Enhanced Visibility (Optional)

Improve diagnostic visibility with custom colors and undercurls:

```vim
highlight DiagnosticUnderlineError guisp=#ff5555 gui=undercurl
highlight DiagnosticUnderlineWarn  guisp=#ffaa00 gui=undercurl
highlight DiagnosticUnderlineInfo  guisp=#00aaff gui=undercurl
highlight DiagnosticUnderlineHint  guisp=#00ff99 gui=undercurl
```

### 4. Apply Changes

Reload your config inside Neovim or restart:
`:source ~/.config/nvim/init.vim`

---

## Useful Debugging

*   **Check loaded scripts:** `:scriptnames`
*   **Check messages:** `:messages`
*   **Check LSP log:** `:edit ~/.local/state/nvim/lsp.log`
*   **Check Neovim binary path:** `:echo v:progpath`
*   **Verify lspconfig loaded:** `:lua print(vim.fn.exists(':LspInfo'))`
    *(Note: `:LspInfo` may be replaced by `:checkhealth vim.lsp` in newer versions.)*
