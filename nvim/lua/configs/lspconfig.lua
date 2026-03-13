require("nvchad.configs.lspconfig").defaults()

-- LSP servers for Go, Python, Frontend, etc.
local servers = {
  "html",
  "cssls",
  "gopls",      -- Go
  "pyright",    -- Python
  "ts_ls",      -- TypeScript/JavaScript
  "eslint",     -- JavaScript/TypeScript linting
  "jsonls",     -- JSON
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
