return {
	{
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

			"hrsh7th/cmp-nvim-lsp",

			{
				"mason-org/mason-lspconfig.nvim",
			},

			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
			},

			{
				"j-hui/fidget.nvim",
				opts = {},
			},
		},

		config = function()
			local lsp = require("lsp.servers")
			local servers = lsp.servers

			-- Add completion capabilities to every LSP.
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			-- Apply custom configuration for each server.
			for server_name, server_config in pairs(servers) do
				vim.lsp.config(server_name, server_config)
			end

			-- Install and automatically enable LSP servers.
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_enable = true,
			})

			-- Install non-LSP tools.
			require("mason-tool-installer").setup({
				ensure_installed = lsp.tools,
			})

			-- Buffer-local LSP mappings.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),

				callback = function(event)
					local map = function(lhs, rhs, desc, mode)
						vim.keymap.set(mode or "n", lhs, rhs, {
							buffer = event.buf,
							desc = desc,
						})
					end

					map("gs", vim.lsp.buf.signature_help, "Signature help")
					map("<leader>grn", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>k", vim.lsp.buf.hover, "Hover")
					map("gk", vim.diagnostic.open_float, "Diagnostic")
				end,
			})
		end,
	},
}
