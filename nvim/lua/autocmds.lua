require "nvchad.autocmds"

-- Set the default directory to open when no arguments are provided
local default_dir = "/Users/genwilliam/Resource/software/nvim_dir"

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Set cwd and open NvimTree",
  callback = function()
    local argc = vim.fn.argc()
    local target_dir

    if argc == 0 then
      target_dir = default_dir
    else
      local arg = vim.fn.argv(0)
      local path = vim.fn.fnamemodify(arg, ":p")

      if vim.fn.isdirectory(path) == 1 then
        target_dir = path
      end
    end

    if target_dir then
      vim.cmd("cd " .. target_dir)

      vim.defer_fn(function()
        local ok, api = pcall(require, "nvim-tree.api")
        if ok then
          api.tree.open()
        end
      end, 50)
    end
  end,
})