return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- TreeSitter for better syntax highlighting and code navigation
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "javascript", "typescript", "tsx",
        "go", "python", "json", "yaml", "markdown",
      },
    },
  },

  -- DAP (Debugger Adapter Protocol) for debugging
  {
    "mfussenegger/nvim-dap",
    ft = { "go", "python", "javascript", "typescript" },
    config = function()
      require "configs.dap"
    end,
  },

  -- DAP UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },

  -- Comments plugin for Ctrl+/
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
    },
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },
}
