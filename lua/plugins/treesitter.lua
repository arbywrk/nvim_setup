return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup()
            require("nvim-treesitter").install({
                "bash",
                "c",
                "cpp",
                "css",
                "diff",
                "html",
                "javascript",
                "json",
                "kotlin",
                "lua",
                "luadoc",
                "markdown",
                "markdown_inline",
                "nix",
                "python",
                "query",
                "toml",
                "vim",
                "vimdoc",
                "rust",
                "ron",
                "sql",
                "zig",
            })
        end,
    },
}
