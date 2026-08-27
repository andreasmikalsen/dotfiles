local map = vim.keymap.set

-- Disable Space's default behavior; Space is the leader key.
map("", "<Space>", "<Nop>", { silent = true })

-- Norwegian keyboard helpers
map({ "n", "v" }, "ø", "[", { silent = true })
map({ "n", "v" }, "æ", "]", { silent = true })
map({ "n", "v" }, "Ø", "{", { silent = true })
map({ "n", "v" }, "Æ", "}", { silent = true })

-- Files / buffers
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write" })
map("n", "<leader>c", "<cmd>bdelete<cr>", { desc = "Close buffer" })
map("n", "<leader>a", "<cmd>qa<cr>", { desc = "Quit all" })

-- Tabs / windows
map("n", "T", "<cmd>tab split<cr>", { desc = "Open buffer in new tab" })
map("n", "<leader>nv", "<cmd>vnew<cr>", { desc = "New vertical split" })

map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })

-- Insert mode
map("i", "jj", "<Esc>", { desc = "Normal mode" })
map("i", "jk", "<Esc>", { desc = "Normal mode" })

-- Keep cursor centered while scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<cr>", {
  desc = "Clear search highlights",
})
