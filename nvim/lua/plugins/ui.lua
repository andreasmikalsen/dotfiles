return {
	-- Colorscheme
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,

		opts = {
			transparent = false,
			italic_comments = false,
			disable_nvimtree_bg = false,
			terminal_colors = true,
			color_overrides = {
				vscBack = "#1a1b26",
			},

			group_overrides = {
				Normal = {
					bg = "#1a1b26",
				},

				NormalNC = {
					bg = "#191a24",
				},

				NvimTreeNormal = {
					bg = "#16161e",
				},

				NvimTreeNormalNC = {
					bg = "#16161e",
				},

				NvimTreeEndOfBuffer = {
					fg = "#16161e",
					bg = "#16161e",
				},

				WinSeparator = {
					fg = "#292e42",
					bg = "#1a1b26",
				},
			},
		},

		config = function(_, opts)
			require("vscode").setup(opts)
			vim.o.background = "dark"
			vim.cmd.colorscheme("vscode")
		end,
	},
	--	{
	--		"folke/tokyonight.nvim",
	--		lazy = false,
	--		priority = 1000,
	--		opts = {
	--			styles = {
	--				comments = { italic = false },
	--			},
	--		},
	--		config = function(_, opts)
	--			require("tokyonight").setup(opts)
	--			vim.cmd.colorscheme("tokyonight-night")
	--		end,
	--	},

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
