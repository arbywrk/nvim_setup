local keymap = require("util.keymap")

keymap.map("n", "<leader>wv", "<C-w>v", "Window: Vertical split")
keymap.map("n", "<leader>ws", "<C-w>s", "Window: Horizontal split")
keymap.map("n", "<leader>wd", "<C-w>c", "Window: Close")
keymap.map("n", "<leader>wo", "<C-w>o", "Window: Close others")
keymap.map("n", "<leader>w=", "<C-w>=", "Window: Equalize sizes")
