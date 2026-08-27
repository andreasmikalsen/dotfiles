local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local highlight_group = augroup("highlight-yank", { clear = true })

autocmd("TextYankPost", {
	desc = "Highlight yanked text",
	group = highlight_group,
	callback = function()
		vim.hl.on_yank()
	end,
})

local function set_trailing_whitespace_highlight()
	vim.api.nvim_set_hl(0, "TrailingWhiteSpace", {
		bg = "#ff0000",
		fg = "#000000",
	})
end

set_trailing_whitespace_highlight()

autocmd("ColorScheme", {
	desc = "Restore trailing whitespace highlight",
	callback = set_trailing_whitespace_highlight,
})

autocmd({ "BufWinEnter", "WinEnter" }, {
	desc = "Highlight trailing whitespace",
	callback = function()
		if not vim.w.trailing_whitespace_match then
			vim.w.trailing_whitespace_match = vim.fn.matchadd("TrailingWhiteSpace", [[\s\+$]])
		end
	end,
})
