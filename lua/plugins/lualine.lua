return {
    "nvim-lualine/lualine.nvim",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    opts = {
        options = {
            theme = "auto",
            globalstatus = true,

            icons_enabled = true,

            section_separators = {
                left = "",
                right = "",
            },

            component_separators = {
                left = "│",
                right = "│",
            },

            disabled_filetypes = {
                statusline = {},
                winbar = {},
            },

            always_divide_middle = true,
            always_show_tabline = false,

            refresh = {
                statusline = 100,
                tabline = 100,
                winbar = 100,
            },
        },

        sections = {
            ------------------------------------------------------------------
            -- Mode
            ------------------------------------------------------------------
            lualine_a = {
                {
                    "mode",
                    icon = "",
                },
            },

            ------------------------------------------------------------------
            -- Git
            ------------------------------------------------------------------
            lualine_b = {
                {
                    "branch",
                    icon = "󰘬",
                },
                {
                    "diff",
                    symbols = {
                        added = " ",
                        modified = " ",
                        removed = " ",
                    },
                },
            },

            ------------------------------------------------------------------
            -- File
            ------------------------------------------------------------------
            lualine_c = {
                {
                    function()
                        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                    end,
                    icon = "",
                },

                {
                    "filename",
                    path = 1,
                    symbols = {
                        modified = " ●",
                        readonly = " !",
                        unnamed = "[No Name]",
                    },
                },
            },

            ------------------------------------------------------------------
            -- Misc
            ------------------------------------------------------------------
            lualine_x = {
                {
                    "searchcount",
                    maxcount = 999,
                },

                {
                    "selectioncount",
                },

                {
                    function()
                        local reg = vim.fn.reg_recording()

                        if reg == "" then
                            return ""
                        end

                        return "󰑋 @" .. reg
                    end,
                },

                {
                    function()
                        local ok, dap = pcall(require, "dap")

                        if not ok then
                            return ""
                        end

                        local session = dap.session()

                        if not session then
                            return ""
                        end

                        if session.stopped_thread_id then
                            return " Stopped"
                        end

                        return " Running"
                    end,
                },

                {
                    "filetype",
                    colored = true,
                    icon_only = false,
                },
            },

            ------------------------------------------------------------------
            -- Diagnostics
            ------------------------------------------------------------------
            lualine_y = {
                {
                    "diagnostics",
                    sources = { "nvim_diagnostic" },

                    symbols = {
                        error = " ",
                        warn = " ",
                        info = " ",
                        hint = "󰌵 ",
                    },

                    update_in_insert = false,
                },

                {
                    "encoding",
                },

                {
                    "fileformat",
                },
            },

            ------------------------------------------------------------------
            -- Cursor
            ------------------------------------------------------------------
            lualine_z = {
                {
                    "progress",
                },

                {
                    "location",
                },
            },
        },

        inactive_sections = {
            lualine_a = {},
            lualine_b = {},

            lualine_c = {
                {
                    "filename",
                    path = 1,
                },
            },

            lualine_x = {
                {
                    "location",
                },
            },

            lualine_y = {},
            lualine_z = {},
        },

        extensions = {
            "quickfix",
            "lazy",
            "mason",
            "fzf",
            "nvim-dap-ui",
        },
    },
}
