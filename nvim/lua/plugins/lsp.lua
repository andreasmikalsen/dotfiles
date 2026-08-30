local lsp = require("lsp.servers")

return {
	-- Mason itself should not be lazy-loaded.
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

	-- Load LSP support only when opening/editing a file.
	{
		"neovim/nvim-lspconfig",
		event = { "VeryLazy", "BufReadPre", "BufNewFile" },

		dependencies = {
			"hrsh7th/cmp-nvim-lsp",

			{
				"mason-org/mason-lspconfig.nvim",
			},
		},

		config = function()
			local servers = lsp.servers

			-- Completion capabilities for every server.
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			-- Server-specific configuration.
			for server_name, server_config in pairs(servers) do
				vim.lsp.config(server_name, server_config)
			end

			-- Install and enable configured servers.
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_enable = true,
			})

			-- Pre-warm Kotlin LSP when Neovim starts inside a Kotlin/Gradle project.
			vim.schedule(function()
				local root = vim.fs.root(vim.uv.cwd(), {
					"settings.gradle",
					"settings.gradle.kts",
					"build.gradle",
					"build.gradle.kts",
					"pom.xml",
				})

				if not root then
					return
				end

				local config = vim.deepcopy(vim.lsp.config["kotlin_lsp"])

				if not config then
					return
				end

				config.name = "kotlin_lsp"
				config.root_dir = root

				vim.lsp.start(config, {
					attach = false,
					silent = true,
				})
			end)

			-- LSP keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),

				callback = function(event)
					local function map(lhs, rhs, desc, mode)
						vim.keymap.set(mode or "n", lhs, rhs, {
							buffer = event.buf,
							desc = desc,
						})
					end

					-- IntelliJ-style navigation
					map("<C-b>", vim.lsp.buf.definition, "Go to declaration")

					map("<C-M-b>", function()
						vim.cmd("Trouble lsp_implementations")
					end, "Go to implementations")

					map("<C-S-b>", function()
						vim.cmd("Trouble lsp_references")
					end, "Find usages")

					-- IntelliJ-style refactoring/actions
					map("<S-F6>", vim.lsp.buf.rename, "Rename")

					-- IntelliJ: Optimize Imports
					map("<C-M-o>", function()
						vim.lsp.buf.code_action({
							apply = true,
							context = {
								only = { "source.organizeImports" },
							},
						})
					end, "Optimize imports")

					-- LSP shortcuts
					map("gs", vim.lsp.buf.signature_help, "Signature help")
					map("<leader>grn", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>k", vim.lsp.buf.hover, "Hover")
					map("gk", vim.diagnostic.open_float, "Diagnostic")
				end,
			})
		end,
	},

	-- Only show LSP progress when an LSP is actually active.
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	-- Don't check/install formatter tools on every startup.
	--
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		cmd = {
			"MasonToolsInstall",
			"MasonToolsInstallSync",
			"MasonToolsUpdate",
			"MasonToolsUpdateSync",
			"MasonToolsClean",
		},

		opts = {
			ensure_installed = vim.list_extend(vim.tbl_keys(lsp.servers), lsp.tools),

			run_on_start = false,
		},
	},
}
