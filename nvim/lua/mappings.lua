require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "<S-Tab>", 'copilot#Accept("\\<CR>")', {
	expr = true,
	replace_keycodes = false,
	silent = true,
	desc = "Copilot accept",
})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
