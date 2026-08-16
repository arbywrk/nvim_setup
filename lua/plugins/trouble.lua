local keymap = require("util.keymap")

keymap.map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)")
keymap.map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)")
keymap.map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", "Symbols (Trouble)")
keymap.map(
    "n",
    "<leader>xl",
    "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
    "LSP Definitions / references / ... (Trouble)"
)
keymap.map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)")
keymap.map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)")

require("trouble").setup({})
