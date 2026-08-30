-- Leader must be defined before plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.diagnostics")
require("config.highlights")

-- Load plugins, leave at the end
require("config.lazy")
