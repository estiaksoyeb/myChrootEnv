# Kotlin LSP Setup for Neovim in Ubuntu Chroot

This guide outlines a working setup for Kotlin development using Neovim and the Kotlin Language Server, including autocompletion and mobile-optimized UI.

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

## 4. Full Configuration (`init.vim`)

Edit or create `~/.config/nvim/init.vim`:
```bash
mkdir -p ~/.config/nvim
nvim ~/.config/nvim/init.vim
```

> [!TIP]
> You can find this full configuration file in the repository at [ubuntu/.config/nvim/init.vim](../ubuntu/.config/nvim/init.vim).


Copy and paste the following full configuration:

```vim
syntax on
set termguicolors
set number

call plug#begin()

" LSP and Treesitter
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Autocompletion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'

call plug#end()

lua << EOF
local cmp = require('cmp')

cmp.setup({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
  },

  sources = {
    { name = 'nvim_lsp' },
  },
})

-- Capabilities for autocompletion
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Kotlin LSP Configuration (Neovim 0.11+ API)
vim.lsp.config('kotlin_language_server', {
  cmd = { '/root/kotlin-ls/server/bin/kotlin-language-server' },
  capabilities = capabilities,
})

vim.lsp.enable('kotlin_language_server')

-- Mobile-Optimized Diagnostics
vim.diagnostic.config({
  virtual_text = false, -- Disable long inline messages for small screens
  underline = true,    -- Keep code underlining
  signs = true,        -- Keep gutter markers
})

-- Keybindings
vim.keymap.set('n', 'gl', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

EOF

" Diagnostic Styling (Undercurls)
highlight DiagnosticUnderlineError guisp=#ff5555 gui=undercurl
highlight DiagnosticUnderlineWarn  guisp=#ffaa00 gui=undercurl
highlight DiagnosticUnderlineInfo  guisp=#00aaff gui=undercurl
highlight DiagnosticUnderlineHint  guisp=#00ff99 gui=undercurl
```

### Install Plugins
Inside Neovim, run:
```vim
:PlugInstall
```
Or from shell:
```bash
nvim +PlugInstall +qall
```

---

## 5. Usage

Open the project root to ensure the LSP detects the project context correctly:

```bash
cd ~/Projects/YourProject
nvim
```

Open a Kotlin file:
`:e app/src/main/kotlin/com/example/MainActivity.kt`

---

## 6. Verify Setup

Inside Neovim:

*   **Check health:** `:checkhealth vim.lsp`
*   **Check active clients:** `:lua print(vim.inspect(vim.lsp.get_clients()))`
*   **Test Autocomplete:** Start typing a Kotlin keyword or variable and press `<Tab>`.

---

## Useful Debugging

*   **Check loaded scripts:** `:scriptnames`
*   **Check messages:** `:messages`
*   **Check LSP log:** `:edit ~/.local/state/nvim/lsp.log`
*   **Check Neovim binary path:** `:echo v:progpath`
*   **Verify lspconfig loaded:** `:lua print(vim.fn.exists(':LspInfo'))`
