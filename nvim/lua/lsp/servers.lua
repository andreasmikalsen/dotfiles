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

	kotlin_lsp = {
		single_file_support = false,
	},

	jdtls = {
		settings = {
			java = {
				configuration = {
					updateBuildConfiguration = "interactive",
				},
			},
		},
	},

	ts_ls = {
		init_options = {
			preferences = {
				includeCompletionsForModuleExports = true,
				includeCompletionsForImportStatements = true,
				includePackageJsonAutoImports = "on",
				importModuleSpecifierPreference = "shortest",
			},
		},
	},
}

local tools = {
	"stylua",
}

return {
	servers = servers,
	tools = tools,
}
