local servers = {
	lua_ls = {
		on_init = function(client)
			client.server_capabilities.documentFormattingProvider = false
		end,

		settings = {
			Lua = {
				format = {
					enable = false,
				},
			},
		},
	},

	kotlin_lsp = {},
	ts_ls = {},
}

local tools = {
	"stylua",
}

return {
	servers = servers,
	tools = tools,
}
