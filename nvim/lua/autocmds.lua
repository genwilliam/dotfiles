require "nvchad.autocmds"

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() ~= 1 then
			return
		end

		local target = vim.fn.argv(0)
		if vim.fn.isdirectory(target) == 1 then
			vim.cmd.cd(vim.fn.fnameescape(target))
		end
	end,
})
