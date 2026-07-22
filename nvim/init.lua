---@diagnostic disable: lowercase-global
---@diagnostic disable-next-line: undefined-global

local nvim = vim

pcall(require, "config")

-- Enable faster startup by caching compiled Lua modules
nvim.loader.enable()

-- turn str into <cmd>str<cr>
local function cmd(str)
	return string.format("<cmd>%s<cr>", str)
end

-- remap function
local function remap(params)
	nvim.api.nvim_set_keymap(
		params[1],
		params[2],
		params[3],
		nvim.tbl_extend("force", {
			silent = true,
		}, params[4] or {})
	)
end

-- remap function without repeat
local function noremap(params)
	nvim.api.nvim_set_keymap(
		params[1],
		params[2],
		params[3],
		nvim.tbl_extend("force", {
			noremap = true,
			silent = true,
		}, params[4] or {})
	)
end

-- set keymap normal mode
local function setmap(params)
	nvim.keymap.set(params[1], params[2], params[3], params[4] or {})
end

-- dont load in netrw
nvim.g.loaded_netrw = 1
nvim.g.loaded_netrwPlugin = 1

-- disable other language providers
nvim.g.loaded_perl_provider = 0
nvim.g.loaded_ruby_provider = 0
nvim.g.loaded_node_provider = 0
nvim.g.loaded_python_provider = 0
nvim.g.loaded_python3_provider = 0

-- Remap space as leader key
noremap({ "", "<Space>", "<Nop>" })
nvim.g.mapleader = " "
nvim.g.maplocalleader = " "

-- :help options
nvim.opt.backup = false -- creates a backup file
nvim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
nvim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
nvim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
nvim.opt.conceallevel = 0 -- so that `` is visible in markdown files
nvim.opt.fileencoding = "utf-8" -- the encoding written to a file
nvim.opt.hlsearch = true -- highlight all matches on previous search pattern
nvim.opt.ignorecase = true -- ignore case in search patterns
nvim.opt.mouse = "a" -- allow the mouse to be used in neovim
nvim.opt.pumheight = 10 -- pop up menu height
nvim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
nvim.opt.showtabline = 1 -- always show tabs
nvim.opt.smartcase = true -- smart case
nvim.opt.smartindent = true -- make indenting smarter again
nvim.opt.splitbelow = true -- force all horizontal splits to go below current window
nvim.opt.splitright = true -- force all vertical splits to go to the right of current window
nvim.opt.swapfile = false -- creates a swapfile
nvim.opt.termguicolors = true -- set term gui colors (most terminals support this)
nvim.opt.timeoutlen = 500 -- time to wait for a mapped sequence to complete (in milliseconds)
nvim.opt.undofile = true -- enable persistent undo
nvim.opt.updatetime = 300 -- faster completion (4000ms default)
nvim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
nvim.opt.expandtab = true -- convert tabs to spaces
nvim.opt.shiftwidth = 2 -- the number of spaces inserted for each indentation
nvim.opt.tabstop = 2 -- insert 2 spaces for a tab
nvim.opt.cursorline = true -- highlight the current line
nvim.opt.number = true -- set numbered lines
nvim.opt.relativenumber = false -- set relative numbered lines
nvim.opt.numberwidth = 4 -- set number column width to 2 {default 4}
nvim.opt.signcolumn = "yes" -- always show the sign column, otherwise it would shift the text each time
nvim.opt.wrap = false -- display lines as one long line
nvim.opt.scrolloff = 8 -- is one of my fav
nvim.opt.sidescrolloff = 8
nvim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
nvim.opt.confirm = true -- ask for confirmation when handling unsaved or read-only files
nvim.opt.foldlevel = 99 -- make all folds open
nvim.opt.shortmess:append("c") -- don't give ins-completion-menu messages;
nvim.opt.winborder = "single"

nvim.g.have_nerd_font = false

-- Sync clipboard between OS and Neovim.
nvim.schedule(function()
	nvim.o.clipboard = "unnamedplus"
end)

-- Highlight trailing spaces
nvim.cmd("highlight TrailingWhiteSpace guibg=#ff0000 guifg=#000000")
nvim.fn.matchadd("TrailingWhiteSpace", [[\s\+$]])

-- Set options
nvim.cmd("set whichwrap+=<,>,[,],h,l")
nvim.cmd("set formatoptions-=cro")
nvim.cmd("set matchpairs+=<:>,“:”,‘:’")

-- Keyboard mapping --
remap({ "n", "ø", "[" })
remap({ "n", "æ", "]" })
remap({ "n", "Ø", "{" })
remap({ "n", "Æ", "}" })
remap({ "v", "ø", "[" })
remap({ "v", "æ", "]" })
remap({ "v", "Ø", "{" })
remap({ "v", "Æ", "}" })

noremap({ "n", "<leader>q", cmd("q") })
noremap({ "n", "<leader>w", cmd("w") })
noremap({ "n", "<leader>c", cmd("bdelete") })
noremap({ "n", "T", cmd("tab split") })

setmap({ "n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlights on search" } })
setmap({ "n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" } })
setmap({ "n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" } })
setmap({ "n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" } })
setmap({ "n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" } })

setmap({ "n", "<leader>nv", cmd("vnew"), { desc = "New windows vertical split" } })
setmap({ "i", "jj", "<ESC>", { desc = "Go to normal mode" } })
setmap({ "i", "jk", "<ESC>", { desc = "Go to normal mode" } })

setmap({ "n", "<C-d>", "<C-d>zz" })
setmap({ "n", "<C-u>", "<C-u>zz" })

-- Diagnostic Config. See `:help vim.diagnostic.Opts`
nvim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = nvim.diagnostic.severity.WARN } },

	-- Can switch between these as you prefer
	virtual_text = true, -- Text shows up at the end of the line
	virtual_lines = false, -- Text shows up underneath the line, with virtual lines

	-- Auto open the float
	jump = {
		on_jump = function(_, bufnr)
			nvim.diagnostic.open_float({
				bufnr = bufnr,
				scope = "cursor",
				focus = false,
			})
		end,
	},
})

-- Highlight when yanking text
nvim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = nvim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		nvim.hl.on_yank()
	end,
})

local keymap = {
	["nvim-tree/nvim-tree.lua"] = {
		{ "<leader>e", cmd("NvimTreeToggle"), desc = "Toggle tree view", mode = { "n", "v" } },
	},
	["stevearc/conform.nvim"] = {
		{
			"<leader>ff",
			function()
				if nvim.bo.filetype == "json" then
					require("formatters/json").format()
				else
					require("conform").format({ async = true })
				end
			end,
			desc = "[F]ormat buffer",
			mode = { "n", "v" },
		},
	},
	["NMAC427/guess-indent.nvim"] = {
		{ "<leader>fg", cmd("GuessIndent"), desc = "[G]uess indent" },
	},
	["kristijanhusak/vim-dadbod-ui"] = {
		{ "<leader>d", cmd("DBUIToggle"), desc = "Toggle [D]atabase" },
	},
	["OXY2DEV/markview.nvim"] = {
		{ "<leader>ns", cmd("Markview splitOpen"), desc = "Open markdown [S]plit view" },
	},
}

-- make list of plugins then append to it
local plugins = {}
local function addplugin(lazy_plug)
	local plugname = lazy_plug[1]
	local plugkeys = keymap[plugname]

	assert(
		plugkeys == nil or lazy_plug.keys == nil,
		string.format("plugin '%s' keyboardshortucts defined both in plugins and keymap configs.", plugname)
	)

	if plugkeys then
		lazy_plug.keys = plugkeys
	end

	table.insert(plugins, lazy_plug)
end

-- Colorschema
addplugin({
	"folke/tokyonight.nvim", -- 'dasupradyumna/midnight.nvim'
	lazy = false,
	priority = 1000,
	config = function()
		nvim.cmd.colorscheme("tokyonight-night") -- 'midnight'
	end,
	opts = {
		styles = {
			comments = { italic = false }, -- Disable italics in comments
		},
	},
})

-- GuessIndent
addplugin({
	"NMAC427/guess-indent.nvim",
	opts = {
		auto_cmd = true,
		override_editorconfig = false,
		on_space_options = { -- A table of vim options when spaces are detected
			["expandtab"] = true,
			["tabstop"] = "detected", -- If the option value is 'detected', The value is set to the automatically detected indent size.
			["softtabstop"] = "detected",
			["shiftwidth"] = "detected",
		},
	},
})

-- GitSigns
addplugin({
	"lewis6991/gitsigns.nvim",
	lazy = false,
	opts = {
		signs = {
			add = { text = "+" }, ---@diagnostic disable-line: missing-fields
			change = { text = "~" }, ---@diagnostic disable-line: missing-fields
			delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
			topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
			changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
		},
	},
})

-- Pending keybinds
addplugin({
	"folke/which-key.nvim",
	opts = {
		delay = 0,
		-- Document existing key chains
		spec = {
			{ "<leader>f", group = "[F]ormat", mode = { "n", "v" } },
			{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
			{ "<leader>t", group = "[T]oggle" },
			{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } }, -- Enable gitsigns recommended keymaps first
			{ "<leader>o", group = "[O]cto GitHub", mode = { "n", "v" } },
			{ "<leader>n", group = "[N]ew", mode = { "n", "v" } },
			{ "gr", group = "LSP Actions", mode = { "n" } },
		},
	},
})

-- Highlight and search for todo comments
addplugin({ "folke/todo-comments.nvim" })

-- Telescope
addplugin({
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		"folke/trouble.nvim",
	},
	lazy = false,
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
		local actions = require("telescope.actions")
		local layout_action = require("telescope.actions.layout")
		local open_with_trouble = require("trouble.sources.telescope").open

		opts.defaults.mappings = {
			i = {
				["<C-n>"] = actions.cycle_history_next,
				["<C-p>"] = actions.cycle_history_prev,
				["<C-j>"] = actions.move_selection_next,
				["<C-k>"] = actions.move_selection_previous,
				["<C-CR>"] = layout_action.toggle_preview,
			},
			n = {
				["n"] = actions.cycle_history_next,
				["p"] = actions.cycle_history_prev,
				["j"] = actions.move_selection_next,
				["k"] = actions.move_selection_previous,
				--['T'] = require('trouble.sources.telescope').open(),
				["?"] = actions.which_key,
				["T"] = open_with_trouble,
			},
		}
		require("telescope").setup(opts)

		local builtin = require("telescope.builtin")
		setmap({ "n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" } })
		setmap({ "n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" } })
		setmap({ "n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" } })
		setmap({ "n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" } })
		setmap({ { "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" } })
		setmap({ "n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" } })
		setmap({ "n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" } })
		setmap({ "n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" } })
		setmap({ "n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" } })
		setmap({ "n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" } })

		-- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
		nvim.api.nvim_create_autocmd("LspAttach", {
			group = nvim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
			callback = function(event)
				local buf = event.buf

				-- Find references for the word under your cursor.
				nvim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })

				-- Jump to the implementation of the word under your cursor.
				setmap({ "n", "gri", builtin.lsp_implementations, { buffer = buf, desc = "[G]oto [I]mplementation" } })

				-- Jump to the definition of the word under your cursor.
				-- To jump back: <C-t>.
				nvim.keymap.set("n", "grd", builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })

				-- Fuzzy find all the symbols in your current document.
				nvim.keymap.set(
					"n",
					"gO",
					builtin.lsp_document_symbols,
					{ buffer = buf, desc = "Open Document Symbols" }
				)

				-- Fuzzy find all the symbols in your current workspace.
				nvim.keymap.set(
					"n",
					"gW",
					builtin.lsp_dynamic_workspace_symbols,
					{ buffer = buf, desc = "Open Workspace Symbols" }
				)

				-- Jump to the type of the word under your cursor.
				nvim.keymap.set(
					"n",
					"grt",
					builtin.lsp_type_definitions,
					{ buffer = buf, desc = "[G]oto [T]ype Definition" }
				)
			end,
		})

		-- Override default behavior and theme when searching
		nvim.keymap.set("n", "<leader>j", function()
			builtin.current_buffer_fuzzy_find()
		end, { desc = "[/] Fuzzily search in current buffer" })

		nvim.keymap.set("n", "<leader>sj", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "[S]earch [/] in Open Files" })
	end,
})

-- File Tree
addplugin({
	"nvim-tree/nvim-tree.lua",
	lazy = false,
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
})

-- LSP Servers
local servers = require("lsp.servers")

-- LSP
addplugin({
	"neovim/nvim-lspconfig",
	lazy = false,
	dependencies = {
		{
			"mason-org/mason.nvim",
			opts = {
				ui = {
					width = 1.0,
					height = 1.0,
					icons = {
						package_installed = "[✔]",
						package_pending = "[…]",
						package_uninstalled = "[⨯]",
					},
				},
			},
		},
		{ "mason-org/mason-lspconfig.nvim", opts = {
			automatic_enable = true,
		} },
		{ "j-hui/fidget.nvim" },
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			opts = {
				ensure_installed = nvim.tbl_keys(servers or {}),
			},
		},
	},
	config = function(_, opts)
		nvim.api.nvim_create_autocmd("LspAttach", {
			group = nvim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					nvim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				map("grn", nvim.lsp.buf.rename, "[R]e[n]ame") -- Rename the variable under your cursor.
				map("gra", nvim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" }) -- Execute a code action
				map("grD", nvim.lsp.buf.declaration, "[G]oto [D]eclaration") -- Goto Declaration.
			end,
		})

		for name, server in pairs(servers) do
			nvim.lsp.config(name, server)
			nvim.lsp.enable(name)
		end
	end,
})

-- Trouble
addplugin({
	"folke/trouble.nvim",
	opts = {
		indent_lines = true,
		focus = true,
		win = {
			opts = {
				type = "split",
				relative = "editor",
				position = "left",
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
				TypeParameter = "type-paramter",
				Variable = "var",
			},
		},
		warn_no_results = true,
		open_no_results = false,
		modes = {
			symbols = {
				multiline = false,
				focus = true,
				win = {
					position = "bottom",
					size = 0.3,
				},
				pinned = true,
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
	},
})

-- TREESITTER
addplugin({
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = {
		auto_install = true,
		ensure_installed = {
			"javascript",
			"typescript",
			"json5",
		},
		sync_install = false,
		highlight = { enable = true },
		indent = { enable = true },
		additional_vim_regex_highlighting = false,
	},
})

-- Formatting
addplugin({
	"stevearc/conform.nvim",
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			local enabled_filetypes = {
				lua = true,
				javascript = true,
				typescript = true,
			}
			if enabled_filetypes[vim.bo[bufnr].filetype] then
				return { timeout_ms = 500 }
			else
				return nil
			end
		end,
		default_format_opts = {
			lsp_format = "fallback", -- Use external formatters if configured, otherwise use LSP formatting.
		},
		-- External formatters
		formatters_by_ft = {
			lua = { "stylua" },
			-- javascript = { "prettierd", "prettier", stop_after_first = true },
		},
	},
})

-- statusline
addplugin({
	"nvim-lualine/lualine.nvim",
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
})

-- Database connection
addplugin({
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{
			"tpope/vim-dadbod",
			lazy = true,
		},
		{ -- Optional
			"kristijanhusak/vim-dadbod-completion",
			ft = { "sql", "mysql", "plsql" },
			lazy = true,
		},
	},
	lazy = not (nvim.env.DADBOD_JSON ~= nil and string.len(nvim.env.DADBOD_JSON) > 0),
	init = function()
		nvim.g.db_ui_use_nerd_fonts = 1
	end,
	config = function()
		if not nvim.env.DADBOD_JSON then
			return
		end
		local json = nvim.json.decode(nvim.env.DADBOD_JSON)

		local dbcons = nvim.g.dbs or {}
		for _, obj in ipairs(json) do
			local dbname = obj.name
			local dburl = obj.url

			if string.len(dbname) > 0 and string.len(dburl) > 0 then
				table.insert(dbcons, { name = dbname, url = dburl })
			else
				print(string.format("failed to parse: %s", nvim.inspect(obj)))
			end
		end
		nvim.g.dbs = dbcons

		if nvim.env.DADBOD_JSON and #dbcons > 0 then
			nvim.defer_fn(function()
				nvim.cmd("DBUI")
			end, 10)
		end
	end,
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
})

-- Completion
addplugin({
	"hrsh7th/nvim-cmp",
	lazy = false,
	dependencies = {
		"neovim/nvim-lspconfig",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/vim-vsnip",
		"hrsh7th/cmp-vsnip",
	},
	opts = function()
		local cmp = require("cmp")
		return {
			enabled = true,
			view = {
				entries = {
					name = "custom",
					selection_order = "top_down",
				},
			},
			sources = {
				{ name = "nvim_lsp" },
				{ name = "vsnip" },
				{ name = "buffer" },
			},
			mapping = {
				["<CR>"] = cmp.mapping.confirm({ select = false }),
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-d>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
			},
		}
	end,
	config = function(_, opts)
		local cmp = require("cmp")
		cmp.setup(opts)
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
		})

		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "buffer" },
			}),
		})

		local lspconfig = require("lspconfig")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		local available_servers = lspconfig.util.available_servers()
		for _, server_name in ipairs(available_servers) do
			lspconfig[server_name].setup({
				capabilities = capabilities,
			})
		end
	end,
})

addplugin({ "windwp/nvim-autopairs", event = "InsertEnter", config = true })

-- DiffView
addplugin({ "sindrets/diffview.nvim" })

addplugin({ "OXY2DEV/markview.nvim", lazy = false, opts = {} })

addplugin({
	"pwntester/octo.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
	},
	opts = {
		picker = "telescope",
		enable_builtin = true,
	},
	keys = {
		{
			"<leader>oi",
			"<CMD>Octo issue list<CR>",
			desc = "List GitHub Issues",
		},
		{
			"<leader>op",
			"<CMD>Octo pr list<CR>",
			desc = "List GitHub PullRequests",
		},
		{
			"<leader>od",
			"<CMD>Octo discussion list<CR>",
			desc = "List GitHub Discussions",
		},
		{
			"<leader>on",
			"<CMD>Octo notification list<CR>",
			desc = "List GitHub Notifications",
		},
		{
			"<leader>os",
			function()
				require("octo.utils").create_base_search_command({ include_current_repo = true })
			end,
			desc = "Search GitHub",
		},
	},
})

-- import extra config if it exists
local ok, extra = pcall(require, "extra")
if ok and type(extra) == "table" then
	for _, p in ipairs(extra.plugins or {}) do
		table.insert(plugins, p)
	end

	pcall(extra.setup)
end

-- BOOTSTRAP package manager
local lazypath = nvim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not nvim.loop.fs_stat(lazypath) then
	nvim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
nvim.opt.rtp:prepend(lazypath)

-- LOAD PACKAGE MANAGER
require("lazy").setup(plugins, {
	ui = {
		size = {
			width = 1.0,
			height = 1.0,
		},
	},
})
