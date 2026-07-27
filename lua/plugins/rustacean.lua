return {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
    config = function()
        vim.g.rustaceanvim = {
            server = {
                capabilities = require("blink.cmp").get_lsp_capabilities(),
                settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true },
                        checkOnSave = { command = "clippy" },
                    },
                },
            },
        }
    end,
}
