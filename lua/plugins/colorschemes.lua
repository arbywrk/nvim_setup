return {
    -- Vague
    {
        "vague-theme/vague.nvim",
        priority = 1000,
        opts = {
            transparent = true, -- If true, background is not set
            bold = true, -- Disable bold globally
            italic = true, -- Disable italic globally
            on_highlights = function(hl, colors) end,
            colors = {
                bg = "#141415",
                inactiveBg = "#1c1c24",
                fg = "#cdcdcd",
                floatBorder = "#878787",
                line = "#252530",
                comment = "#606079",
                builtin = "#b4d4cf",
                func = "#c48282",
                string = "#e8b589",
                number = "#e0a363",
                property = "#c3c3d5",
                constant = "#aeaed1",
                parameter = "#bb9dbd",
                visual = "#333738",
                error = "#d8647e",
                warning = "#f3be7c",
                hint = "#7e98e8",
                operator = "#90a0b5",
                keyword = "#6e94b2",
                type = "#9bb4bc",
                search = "#405065",
                plus = "#7fa563",
                delta = "#f3be7c",
            },
        },
        init = function()
            vim.cmd.colorscheme("vague")
        end,
    },
    -- Catppuccin
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                integrations = {
                    blink_cmp = true,
                    gitsigns = true,
                    nvimtree = true,
                    treesitter = true,
                    fzf_lua = true,
                },
            })
        end,
        init = function()
            -- vim.cmd.colorscheme("catppuccin")
        end,
    },
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = true,
        opts = {
            terminal_colors = true, -- add neovim terminal colors
            undercurl = true,
            underline = true,
            bold = true,
            italic = {
                strings = true,
                emphasis = true,
                comments = true,
                operators = false,
                folds = true,
            },
            strikethrough = true,
            invert_selection = false,
            invert_signs = false,
            invert_tabline = false,
            invert_intend_guides = false,
            inverse = true, -- invert background for search, diffs, statuslines and errors
            contrast = "", -- can be "hard", "soft" or empty string
            palette_overrides = {},
            overrides = {},
            dim_inactive = false,
            transparent_mode = true,
        },
        init = function()
            -- vim.cmd("colorscheme gruvbox")
        end,
    },
    -- Monokai Pro
    {
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent_background = true,
            terminal_colors = true,
            devicons = true,
            styles = {
                comment = { italic = true },
                keyword = { italic = true },
                type = { italic = true },
                storageclass = { italic = true },
                structure = { italic = true },
                parameter = { italic = true },
                annotation = { italic = true },
                tag_attribute = { italic = true },
            },
            filter = "spectrum",
            inc_search = "background",
            background_clear = {
                "toggleterm",
                "fzf-lua",
                "renamer",
                "notify",
            },
            plugins = {
                bufferline = {
                    underline_selected = false,
                    underline_visible = false,
                },
                indent_blankline = {
                    context_highlight = "default",
                    context_start_underline = false,
                },
            },
            override = function(_) end,
        },
        init = function()
            -- vim.cmd("colorscheme monokai-pro") -- apply the collor (set as default)
        end,
    },
    -- Tokyo Night Theme
    {
        "folke/tokyonight.nvim",
        priority = 1000, -- Make sure to load this before all the other start plugins.
        transparent = true,
        opts = {},
    },
}
