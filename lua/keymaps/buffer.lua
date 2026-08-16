local keymap = require("util.keymap")

keymap.map("n", "<leader>bn", "<cmd>bnext<cr>", "Buffer: Next")
keymap.map("n", "<leader>bp", "<cmd>bprevious<cr>", "Buffer: Previous")
keymap.map("n", "<leader>bd", "<cmd>bdelete<cr>", "Buffer: Delete")
