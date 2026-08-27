return {
	{
		"kristijanhusak/vim-dadbod-ui",

		dependencies = {
			{
				"tpope/vim-dadbod",
				lazy = true,
			},

			{
				"kristijanhusak/vim-dadbod-completion",
				ft = { "sql", "mysql", "plsql" },
				lazy = true,
			},
		},

		lazy = not (vim.env.DADBOD_JSON ~= nil and #vim.env.DADBOD_JSON > 0),

		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},

		keys = {
			{
				"<leader>d",
				"<cmd>DBUIToggle<cr>",
				desc = "Toggle [D]atabase",
			},
		},

		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,

		config = function()
			local raw = vim.env.DADBOD_JSON
			if not raw or raw == "" then
				return
			end

			local ok, json = pcall(vim.json.decode, raw)
			if not ok then
				vim.notify("Failed to parse DADBOD_JSON", vim.log.levels.ERROR)
				return
			end

			local dbs = vim.g.dbs or {}

			for _, obj in ipairs(json) do
				if obj.name and obj.url and obj.name ~= "" and obj.url ~= "" then
					table.insert(dbs, {
						name = obj.name,
						url = obj.url,
					})
				end
			end

			vim.g.dbs = dbs

			if #dbs > 0 then
				vim.schedule(function()
					vim.cmd("DBUI")
				end)
			end
		end,
	},
}
