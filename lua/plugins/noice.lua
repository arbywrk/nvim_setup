return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        {
            "rcarriga/nvim-notify",
            opts = {
                stages = "fade_in_slide_out",
                fps = 60,
                timeout = 500,
                render = "minimal",
                top_down = false,
            },
        },
    },
    opts = {
        lsp = {
            progress = { enabled = false }, -- fidget handles LSP progress
            hover = { enabled = true },
            signature = { enabled = true },
        },
        routes = {
            {
                view = "notify",
                filter = { event = "msg_showmode" },
            },
        },
        presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = true,
            lsp_doc_border = true,
        },
    },
}
