syntax on
set termguicolors
set number

call plug#begin()

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

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


local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('kotlin_language_server', {
  cmd = { '/root/kotlin-ls/server/bin/kotlin-language-server' },
  capabilities = capabilities,
})

vim.lsp.enable('kotlin_language_server')


vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  signs = true,
})

vim.keymap.set('n', 'gl', vim.diagnostic.open_float)

EOF

highlight DiagnosticUnderlineError guisp=#ff5555 gui=undercurl
highlight DiagnosticUnderlineWarn  guisp=#ffaa00 gui=undercurl
highlight DiagnosticUnderlineInfo  guisp=#00aaff gui=undercurl
highlight DiagnosticUnderlineHint  guisp=#00ff99 gui=undercurl
