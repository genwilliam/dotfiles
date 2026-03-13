require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local terminal_bufnr = nil

local function close_current_window_or_terminal()
	if vim.bo.buftype == "terminal" then
		vim.cmd "bd!"
	else
		vim.cmd "q"
	end
end

local function setup_terminal_keymaps(bufnr)
	map("n", "q", "<cmd>bd!<CR>", { buffer = bufnr, desc = "Terminal: close buffer" })
	map("t", "<leader>q", "<C-\\><C-n><cmd>bd!<CR>", { buffer = bufnr, desc = "Terminal: close buffer" })
end

local function open_single_terminal()
	if terminal_bufnr and vim.api.nvim_buf_is_valid(terminal_bufnr) then
		local wins = vim.fn.win_findbuf(terminal_bufnr)
		if #wins > 0 then
			vim.api.nvim_set_current_win(wins[1])
		else
			vim.cmd "split"
			vim.api.nvim_win_set_buf(0, terminal_bufnr)
		end
		vim.cmd "startinsert"
		return
	end

	vim.cmd "split | terminal"
	terminal_bufnr = vim.api.nvim_get_current_buf()
	setup_terminal_keymaps(terminal_bufnr)

	vim.api.nvim_create_autocmd({ "TermClose", "BufWipeout" }, {
		buffer = terminal_bufnr,
		once = true,
		callback = function()
			terminal_bufnr = nil
		end,
	})
end

-- Copy VS Code keybindings
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Terminal at bottom
map("n", "<leader>t", open_single_terminal, { desc = "Open terminal at bottom" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: back to normal mode" })
map("n", "<leader>q", close_current_window_or_terminal, { desc = "Close current window" })

-- File explorer (NvimTree)
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

-- Telescope (Find files - Ctrl+P like VS Code)
map("n", "<C-p>", ":Telescope find_files<CR>", { desc = "Find files" })

-- Telescope grep (Global search - Ctrl+Shift+F)
map("n", "<C-F>", ":Telescope live_grep<CR>", { desc = "Global search" })

-- Telescope symbols (Search symbols/commands)
map("n", "<leader>/", ":Telescope current_buffer_fuzzy_find<CR>", { desc = "Search in current buffer" })

-- LSP actions
map("n", "gd", ":lua vim.lsp.buf.definition()<CR>", { desc = "Go to Definition" })
map("n", "gr", ":lua vim.lsp.buf.references()<CR>", { desc = "Show References" })
map("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", { desc = "Go to Implementation" })
map("n", "K", ":lua vim.lsp.buf.hover()<CR>", { desc = "Hover" })
map("n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
map("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>", { desc = "Code action" })

-- Format code
map("n", "<leader>fmt", ":lua require('conform').format()<CR>", { desc = "Format buffer" })

-- Comments (Ctrl+/)
map("n", "<C-/>", "gcc", { desc = "Toggle comment" })
map("v", "<C-/>", "gc", { desc = "Toggle comment" })

-- DAP (Debugging)
map("n", "<F5>", ":DapContinue<CR>", { desc = "Debug: Continue" })
map("n", "<F9>", ":DapToggleBreakpoint<CR>", { desc = "Debug: Toggle Breakpoint" })
map("n", "<F10>", ":DapStepOver<CR>", { desc = "Debug: Step Over" })
map("n", "<F11>", ":DapStepInto<CR>", { desc = "Debug: Step Into" })
map("n", "<F23>", ":DapStepOut<CR>", { desc = "Debug: Step Out" })  -- Shift+F11

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

