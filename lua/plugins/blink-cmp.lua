return {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",

    opts = {
        keymap = { preset = "default" },

        appearance = {
            nerd_font_variant = "mono",
        },

        completion = { documentation = { auto_show = false } },

        sources = {
            default = { "lazydev", "lsp", "path", "snippets", "buffer" },
            providers = {
                lazydev = {
                    name = "LazyDev",
                    module = "lazydev.integrations.blink",
                    score_offset = 100,
                },
            },
        },

        fuzzy = { implementation = "prefer_rust" },
    },
    opts_extend = { "sources.default" },
}
