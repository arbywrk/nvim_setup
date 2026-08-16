return {
    "ibhagwan/fzf-lua",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    config = function()
        local fzf = require("fzf-lua")

        fzf.setup({
            "default-title",

            fzf_colors = true,

            winopts = {
                height = 0.90,
                width = 0.90,
                row = 0.35,
                col = 0.50,
                border = "rounded",

                preview = {
                    layout = "vertical",
                    vertical = "right:55%",
                    scrollbar = "float",
                },
            },

            files = {
                git_icons = true,
                cwd_prompt = false,
            },

            grep = {
                rg_glob = true,
                hidden = true,
            },

            git = {
                files = {
                    prompt = "Git Files❯ ",
                },
                status = {
                    preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
                },
            },

            keymap = {
                builtin = {
                    ["<C-d>"] = "preview-page-down",
                    ["<C-u>"] = "preview-page-up",
                    ["<C-h>"] = "toggle-help",
                },

                fzf = {
                    -- Navigation
                    ["ctrl-j"] = "down",
                    ["ctrl-k"] = "up",
                    ["tab"] = "down",
                    ["shift-tab"] = "up",

                    ["ctrl-n"] = "down",
                    ["ctrl-p"] = "up",

                    -- Preview
                    ["ctrl-f"] = "preview-page-down",
                    ["ctrl-b"] = "preview-page-up",

                    -- Multi-select
                    ["alt-j"] = "toggle+down",
                    ["alt-k"] = "toggle+up",

                    -- Preview
                    ["alt-p"] = "toggle-preview",

                    -- History
                    ["ctrl-r"] = "toggle-sort",

                    -- Accept
                    ["enter"] = "accept",
                },
            },
        })

        fzf.register_ui_select()

        ------------------------------------------------------------------
        -- Search
        ------------------------------------------------------------------

        vim.keymap.set("n", "\\", fzf.files, {
            desc = "Files",
        })

        vim.keymap.set("n", "<leader>sf", fzf.files, {
            desc = "[S]earch [F]iles",
        })

        vim.keymap.set("n", "<leader>sg", fzf.live_grep, {
            desc = "[S]earch by [G]rep",
        })

        vim.keymap.set("n", "<leader>sw", fzf.grep_cword, {
            desc = "[S]earch current [W]ord",
        })

        vim.keymap.set("n", "<leader>sb", fzf.buffers, {
            desc = "[S]earch [B]uffers",
        })

        vim.keymap.set("n", "<leader>so", fzf.oldfiles, {
            desc = "[S]earch [O]ld files",
        })

        vim.keymap.set("n", "<leader>sh", fzf.help_tags, {
            desc = "[S]earch [H]elp",
        })

        vim.keymap.set("n", "<leader>sk", fzf.keymaps, {
            desc = "[S]earch [K]eymaps",
        })

        vim.keymap.set("n", "<leader>sd", fzf.diagnostics_workspace, {
            desc = "[S]earch [D]iagnostics",
        })

        vim.keymap.set("n", "<leader>sc", fzf.commands, {
            desc = "[S]earch [C]ommands",
        })

        vim.keymap.set("n", "<leader>sm", fzf.marks, {
            desc = "[S]earch [M]arks",
        })

        vim.keymap.set("n", "<leader>sr", fzf.resume, {
            desc = "[S]earch [R]esume",
        })

        vim.keymap.set("n", "<leader>ss", fzf.builtin, {
            desc = "[S]earch [S]ources",
        })

        vim.keymap.set("n", "<leader><leader>", fzf.buffers, {
            desc = "Switch Buffer",
        })

        ------------------------------------------------------------------
        -- Buffer search
        ------------------------------------------------------------------

        vim.keymap.set("n", "<leader>/", function()
            fzf.blines({
                winopts = {
                    preview = {
                        hidden = true,
                    },
                },
            })
        end, {
            desc = "Search in Buffer",
        })

        vim.keymap.set("n", "<leader>s/", function()
            fzf.live_grep({
                grep_open_files = true,
                prompt = "Open Files❯ ",
            })
        end, {
            desc = "Search Open Files",
        })

        ------------------------------------------------------------------
        -- Git
        ------------------------------------------------------------------

        vim.keymap.set("n", "<leader>gf", fzf.git_files, {
            desc = "[G]it [F]iles",
        })

        vim.keymap.set("n", "<leader>gs", fzf.git_status, {
            desc = "[G]it [S]tatus",
        })

        vim.keymap.set("n", "<leader>gc", fzf.git_commits, {
            desc = "[G]it [C]ommits",
        })

        vim.keymap.set("n", "<leader>gb", fzf.git_branches, {
            desc = "[G]it [B]ranches",
        })

        vim.keymap.set("n", "<leader>gl", fzf.git_bcommits, {
            desc = "[G]it File [L]og",
        })

        ------------------------------------------------------------------
        -- LSP
        ------------------------------------------------------------------

        vim.keymap.set("n", "gd", fzf.lsp_definitions, {
            desc = "Goto Definition",
        })

        vim.keymap.set("n", "gr", fzf.lsp_references, {
            desc = "Goto References",
        })

        vim.keymap.set("n", "gi", fzf.lsp_implementations, {
            desc = "Goto Implementation",
        })

        vim.keymap.set("n", "gt", fzf.lsp_typedefs, {
            desc = "Goto Type Definition",
        })

        vim.keymap.set("n", "<leader>sn", function()
            fzf.files({
                cwd = vim.fn.stdpath("config"),
            })
        end, {
            desc = "Neovim Config",
        })
    end,
}
