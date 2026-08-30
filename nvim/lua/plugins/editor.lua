return {
	-- File explorer
	{
		"nvim-tree/nvim-tree.lua",
		lazy = true,
		cmd = {
			"NvimTreeToggle",
			"NvimTreeOpen",
			"NvimTreeFindFile",
		},
		keys = {
			{
				"<leader>e",
				"<cmd>NvimTreeToggle<cr>",
				desc = "Toggle tree view",
			},
		},
		opts = {
			hijack_netrw = true,
			disable_netrw = false,

			update_focused_file = {
				enable = true,
			},

			live_filter = {
				always_show_folders = false,
			},

			git = {
				ignore = false,
			},

			filters = {
				dotfiles = false,
			},

			view = {
				adaptive_size = true,
			},

			renderer = {
				add_trailing = true,
				indent_width = 2,

				indent_markers = {
					enable = true,
					inline_arrows = true,
					icons = {
						corner = "└",
						edge = "│",
						item = "├",
						bottom = "─",
						none = " ",
					},
				},

				icons = {
					git_placement = "after",
					modified_placement = "after",
					diagnostics_placement = "signcolumn",
					bookmarks_placement = "signcolumn",
					padding = "",

					show = {
						file = false,
						folder = false,
						folder_arrow = false,
					},

					glyphs = {
						symlink = "->",
						bookmark = "B",

						folder = {
							symlink = "->",
							symlink_open = "->",
						},

						git = {
							unstaged = "*",
							staged = "+",
							unmerged = "§",
							renamed = ">",
							untracked = "?",
							deleted = "&",
							ignored = "=",
						},
					},
				},
			},

			diagnostics = {
				enable = true,
				show_on_dirs = true,
				icons = {
					hint = "h",
					info = "i",
					warning = "W",
					error = "E",
				},
			},
		},
	},

	-- Detect indentation
	{
		"NMAC427/guess-indent.nvim",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"<leader>fg",
				"<cmd>GuessIndent<cr>",
				desc = "[G]uess indent",
			},
		},
		opts = {
			auto_cmd = true,
			override_editorconfig = false,

			on_space_options = {
				expandtab = true,
				tabstop = "detected",
				softtabstop = "detected",
				shiftwidth = "detected",
			},
		},
	},

	-- Formatting
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",

		keys = {
			{
				"<leader>ff",
				function()
					if vim.bo.filetype == "json" then
						require("formatters.json").format()
					else
						require("conform").format({ async = true })
					end
				end,
				mode = { "n", "v" },
				desc = "[F]ormat buffer",
			},
		},

		opts = {
			notify_on_error = false,

			format_on_save = function(bufnr)
				local filetype = vim.bo[bufnr].filetype

				if filetype == "kotlin" then
					return {
						timeout_ms = 3000,
						lsp_format = "fallback",
					}
				end

				local enabled_filetypes = {
					lua = true,
					javascript = true,
					typescript = true,
				}

				if enabled_filetypes[filetype] then
					return {
						timeout_ms = 500,
					}
				end
			end,

			default_format_opts = {
				lsp_format = "fallback",
			},

			formatters_by_ft = {
				lua = { "stylua" },
				kotlin = {
					lsp_format = "fallback",
				},
			},
		},
	},

	-- Auto-close brackets, quotes, etc.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	-- Markdown preview
	{
		"OXY2DEV/markview.nvim",
		lazy = false,
		opts = {},
		keys = {
			{
				"<leader>ns",
				"<cmd>Markview splitOpen<cr>",
				desc = "Open markdown [S]plit view",
			},
		},
	},
}
