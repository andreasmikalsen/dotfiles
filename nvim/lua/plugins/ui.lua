return {
	-- Colorscheme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			styles = {
				comments = { italic = false },
			},
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},

	-- Keybinding hints
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 0,
			spec = {
				{ "<leader>f", group = "[F]ormat", mode = { "n", "v" } },
				{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
				{ "<leader>o", group = "[O]cto GitHub", mode = { "n", "v" } },
				{ "<leader>n", group = "[N]ew", mode = { "n", "v" } },
				{ "gr", group = "LSP Actions", mode = "n" },
			},
		},
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = {
				icons_enabled = false,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				always_divide_middle = false,
				globalstatus = false,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "filename" },
				lualine_c = { "diff", "diagnostics", "branch" },
				lualine_x = { "encoding", "fileformat", "filetype", "location" },
				lualine_y = {},
				lualine_z = {},
			},
			inactive_sections = {
				lualine_a = { "filename" },
				lualine_b = {},
				lualine_c = { "diff", "diagnostics", "branch" },
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
		},
	},
}
