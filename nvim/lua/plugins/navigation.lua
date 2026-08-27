return {
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},

		opts = {
			defaults = {},
			pickers = {
				find_files = {
					no_ignore = false,
					hidden = true,
				},
			},
		},

		config = function(_, opts)
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local layout = require("telescope.actions.layout")

			opts.defaults.mappings = {
				i = {
					["<C-n>"] = actions.cycle_history_next,
					["<C-p>"] = actions.cycle_history_prev,
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
					["<C-CR>"] = layout.toggle_preview,

					["<C-t>"] = function(prompt_bufnr)
						require("trouble.sources.telescope").open(prompt_bufnr)
					end,
				},

				n = {
					n = actions.cycle_history_next,
					p = actions.cycle_history_prev,
					j = actions.move_selection_next,
					k = actions.move_selection_previous,
					["?"] = actions.which_key,

					T = function(prompt_bufnr)
						require("trouble.sources.telescope").open(prompt_bufnr)
					end,
				},
			}

			telescope.setup(opts)

			local builtin = require("telescope.builtin")
			local map = vim.keymap.set

			map("n", "<leader>sh", builtin.help_tags, {
				desc = "[S]earch [H]elp",
			})

			map("n", "<leader>sk", builtin.keymaps, {
				desc = "[S]earch [K]eymaps",
			})

			map("n", "<leader>sf", builtin.find_files, {
				desc = "[S]earch [F]iles",
			})

			map("n", "<leader>ss", builtin.builtin, {
				desc = "[S]earch [S]elect Telescope",
			})

			map({ "n", "v" }, "<leader>sw", builtin.grep_string, {
				desc = "[S]earch current [W]ord",
			})

			map("n", "<leader>sg", builtin.live_grep, {
				desc = "[S]earch by [G]rep",
			})

			map("n", "<leader>sd", builtin.diagnostics, {
				desc = "[S]earch [D]iagnostics",
			})

			map("n", "<leader>sr", builtin.resume, {
				desc = "[S]earch [R]esume",
			})

			map("n", "<leader>sc", builtin.commands, {
				desc = "[S]earch [C]ommands",
			})

			map("n", "<leader><leader>", builtin.buffers, {
				desc = "Find existing buffers",
			})

			map("n", "<leader>j", builtin.current_buffer_fuzzy_find, {
				desc = "Search current buffer",
			})

			map("n", "<leader>sj", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, {
				desc = "[S]earch in open files",
			})

			-- Telescope-based LSP navigation
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),

				callback = function(event)
					local options = { buffer = event.buf }

					map(
						"n",
						"grr",
						builtin.lsp_references,
						vim.tbl_extend("force", options, {
							desc = "[G]oto [R]eferences",
						})
					)

					map(
						"n",
						"gri",
						builtin.lsp_implementations,
						vim.tbl_extend("force", options, {
							desc = "[G]oto [I]mplementation",
						})
					)

					map(
						"n",
						"grd",
						builtin.lsp_definitions,
						vim.tbl_extend("force", options, {
							desc = "[G]oto [D]efinition",
						})
					)

					map(
						"n",
						"gO",
						builtin.lsp_document_symbols,
						vim.tbl_extend("force", options, {
							desc = "Document symbols",
						})
					)

					map(
						"n",
						"gW",
						builtin.lsp_dynamic_workspace_symbols,
						vim.tbl_extend("force", options, {
							desc = "Workspace symbols",
						})
					)

					map(
						"n",
						"grt",
						builtin.lsp_type_definitions,
						vim.tbl_extend("force", options, {
							desc = "[G]oto [T]ype Definition",
						})
					)
				end,
			})
		end,
	},

	-- Trouble
	{
		"folke/trouble.nvim",
		cmd = "Trouble",

		keys = {
			{ "gd", "<cmd>Trouble lsp_definitions<cr>" },
			{ "gD", "<cmd>Trouble lsp_declarations<cr>" },
			{ "gi", "<cmd>Trouble lsp_implementations<cr>" },
			{ "go", "<cmd>Trouble lsp_type_definitions<cr>" },
			{ "gr", "<cmd>Trouble lsp_references<cr>" },
			{ "g?", "<cmd>Trouble diagnostics<cr>" },
			{
				"<leader>ts",
				"<cmd>Trouble symbols toggle<cr>",
				desc = "Symbols",
			},
			{ "gq", "<cmd>Trouble close<cr>" },
		},

		opts = {
			indent_lines = true,
			focus = true,

			win = {
				type = "split",
				relative = "editor",
				position = "left",
			},

			warn_no_results = true,
			open_no_results = false,

			modes = {
				symbols = {
					multiline = false,
					focus = true,
					pinned = true,

					win = {
						position = "bottom",
						size = 0.3,
					},

					preview = {
						type = "main",
						scratch = true,
					},

					formatters = {
						text = function(o)
							return o.value:gsub("%s+", " ")
						end,
					},
				},
			},

			icons = {
				indent = {
					top = "│ ",
					middle = "├╴",
					last = "└╴",
					fold_open = "-",
					fold_closed = "+",
					ws = " ",
				},

				folder_closed = "Dir",
				folder_open = "Dir",

				kinds = {
					Array = "arr",
					Boolean = "bool",
					Class = "class",
					Constant = "const",
					Constructor = "cotr",
					Enum = "enum",
					EnumMember = "enum-member",
					Event = "event",
					Field = "field",
					File = "file",
					Function = "func",
					Interface = "interface",
					Key = "key",
					Method = "method",
					Module = "module",
					Namespace = "namespace",
					Null = "null",
					Number = "num",
					Object = "obj",
					Operator = "op",
					Package = "pkg",
					Property = "prop",
					String = "str",
					Struct = "struct",
					TypeParameter = "type-parameter",
					Variable = "var",
				},
			},
		},
	},
}
