local opt = vim.opt
local g = vim.g

-- Disable built-in file explorer
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- Disable unused language providers
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python_provider = 0
g.loaded_python3_provider = 0

-- Nerd Font is provided by WezTerm
g.have_nerd_font = true

-- General
opt.backup = false
opt.clipboard = "unnamedplus"
opt.cmdheight = 1
opt.completeopt = { "menuone", "noselect" }
opt.conceallevel = 0
opt.fileencoding = "utf-8"
opt.mouse = "a"
opt.pumheight = 10
opt.showmode = false
opt.confirm = true

-- Search
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Windows / splits
opt.splitbelow = true
opt.splitright = true
opt.winborder = "single"

-- UI
opt.termguicolors = true
opt.cursorline = true
opt.number = true
opt.relativenumber = false
opt.numberwidth = 4
opt.signcolumn = "yes"
opt.showtabline = 1
opt.wrap = false

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Files / undo
opt.swapfile = false
opt.undofile = true
opt.writebackup = false

-- Timing
opt.timeoutlen = 500
opt.updatetime = 300

-- Folding
opt.foldlevel = 99

-- GUI clients
opt.guifont = "monospace:h17"

-- Misc
opt.shortmess:append("c")
opt.whichwrap:append("<,>,[,],h,l")
opt.formatoptions:remove({ "c", "r", "o" })
opt.matchpairs:append({ "<:>", "“:”", "‘:’" })
