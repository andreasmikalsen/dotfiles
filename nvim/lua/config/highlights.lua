local set = vim.api.nvim_set_hl

local function apply_jetbrains_colors()
	local languages = { "kotlin", "java" }

	for _, lang in ipairs(languages) do
		-- Treesitter syntax
		set(0, "@keyword." .. lang, {
			fg = "#CC7832",
		})

		set(0, "@string." .. lang, {
			fg = "#6A8759",
		})

		set(0, "@number." .. lang, {
			fg = "#6897BB",
		})

		set(0, "@comment." .. lang, {
			fg = "#808080",
		})

		set(0, "@function." .. lang, {
			fg = "#FFC66D",
		})

		set(0, "@constructor." .. lang, {
			fg = "#FFC66D",
		})

		set(0, "@type." .. lang, {
			fg = "#A9B7C6",
		})

		set(0, "@attribute." .. lang, {
			fg = "#BBB529",
		})

		-- LSP semantic tokens
		set(0, "@lsp.type.class." .. lang, {
			fg = "#A9B7C6",
		})

		set(0, "@lsp.type.interface." .. lang, {
			fg = "#A9B7C6",
		})

		set(0, "@lsp.type.enum." .. lang, {
			fg = "#A9B7C6",
		})

		set(0, "@lsp.type.type." .. lang, {
			fg = "#A9B7C6",
		})

		set(0, "@lsp.type.method." .. lang, {
			fg = "#FFC66D",
		})

		set(0, "@lsp.type.function." .. lang, {
			fg = "#FFC66D",
		})

		set(0, "@lsp.type.property." .. lang, {
			fg = "#9876AA",
		})

		set(0, "@lsp.type.decorator." .. lang, {
			fg = "#BBB529",
		})

		set(0, "@lsp.type.string." .. lang, {
			fg = "#6A8759",
		})

		set(0, "@lsp.type.number." .. lang, {
			fg = "#6897BB",
		})

		set(0, "@lsp.type.keyword." .. lang, {
			fg = "#CC7832",
		})
	end
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("language-colors", { clear = true }),
	callback = apply_jetbrains_colors,
})

apply_jetbrains_colors()
