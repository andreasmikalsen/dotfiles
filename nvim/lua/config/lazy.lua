local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
	{ import = "plugins" },
}

-- Optional machine-specific additions
local ok, extra = pcall(require, "extra")

if ok and type(extra) == "table" then
	for _, plugin in ipairs(extra.plugins or {}) do
		table.insert(plugins, plugin)
	end
end

require("lazy").setup(plugins, {
	ui = {
		size = {
			width = 1.0,
			height = 1.0,
		},
	},
})

if ok and type(extra.setup) == "function" then
	pcall(extra.setup)
end
