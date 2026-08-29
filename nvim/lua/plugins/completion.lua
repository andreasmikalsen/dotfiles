return {
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },

		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/vim-vsnip",
			"hrsh7th/cmp-vsnip",
		},

		config = function()
			local cmp = require("cmp")

			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},

				view = {
					entries = {
						name = "custom",
						selection_order = "top_down",
					},
				},

				formatting = {
					format = function(entry, item)
						if entry.source.name == "nvim_lsp" then
							local completion = entry.completion_item

							if completion.detail then
								item.menu = completion.detail
							elseif completion.labelDetails and completion.labelDetails.description then
								item.menu = completion.labelDetails.description
							else
								item.menu = "[LSP]"
							end
						else
							item.menu = "[" .. entry.source.name .. "]"
						end

						return item
					end,
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

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "vsnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Command-line completion
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),

				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),

				matching = {
					disallow_symbol_nonprefix_matching = false,
				},
			})
		end,
	},
}
