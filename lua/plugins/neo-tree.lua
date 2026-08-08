return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false, -- neo-tree will lazily load itself
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    },
    cmd = "Neotree",
    keys = {
        { "<leader>\\", ":Neotree toggle<CR>", desc = "NeoTree reveal", silent = true },
    },
    opts = {
        filesystem = {
            window = {
                position = "right",
                mappings = {
                    ["<leader>\\"] = "close_window",
                },
            },
            -- group_empty_dirs = true,
        },
    },
}
