return {
	-- Git signs in the sign column
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	-- Git diff viewer
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
		},
	},

	-- GitHub integration
	{
		"pwntester/octo.nvim",
		cmd = "Octo",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			picker = "telescope",
			enable_builtin = true,
		},
		keys = {
			{
				"<leader>oi",
				"<cmd>Octo issue list<cr>",
				desc = "List GitHub Issues",
			},
			{
				"<leader>op",
				"<cmd>Octo pr list<cr>",
				desc = "List GitHub Pull Requests",
			},
			{
				"<leader>od",
				"<cmd>Octo discussion list<cr>",
				desc = "List GitHub Discussions",
			},
			{
				"<leader>on",
				"<cmd>Octo notification list<cr>",
				desc = "List GitHub Notifications",
			},
			{
				"<leader>os",
				function()
					require("octo.utils").create_base_search_command({
						include_current_repo = true,
					})
				end,
				desc = "Search GitHub",
			},
		},
	},
}
