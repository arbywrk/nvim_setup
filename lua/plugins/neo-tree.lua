local keymap = require("util.keymap")

keymap.map("n", "<leader>\\", ":Neotree toggle<CR>", "NeoTree reveal", { silent = true })

require("neo-tree").setup({
    use_popups_for_input = false,
    filesystem = {
        window = {
            position = "right",
            mappings = {
                ["<leader>\\"] = "close_window",
            },
        },
        -- group_empty_dirs = true,
    },
})
