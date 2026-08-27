-- Set C compiler to the wrappers shipped with this Neovim config.
local config_dir = vim.fn.stdpath("config")
vim.env.CC = vim.fs.joinpath(config_dir, "zig-cc.cmd")
vim.env.CXX = vim.fs.joinpath(config_dir, "zig-cxx.cmd")
