vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,

	float = {
		border = "rounded",
		source = "if_many",
	},

	underline = {
		severity = {
			min = vim.diagnostic.severity.WARN,
		},
	},

	virtual_text = true,
	virtual_lines = false,

	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({
				bufnr = bufnr,
				scope = "cursor",
				focus = false,
			})
		end,
	},
})

local function diagnostic_highlights()
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
		undercurl = true,
		sp = "#f44747",
	})

	vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", {
		undercurl = true,
		sp = "#cca700",
	})

	vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", {
		undercurl = true,
		sp = "#3794ff",
	})

	vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", {
		undercurl = true,
		sp = "#4ec9b0",
	})
end

diagnostic_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = diagnostic_highlights,
})
