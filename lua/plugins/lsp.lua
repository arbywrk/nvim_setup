return {
    {
        -- Extend Lua LSP with Neovim runtime types.
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                "nvim-dap-ui",
            },
        },
    },
    {
        -- Centralize LSP defaults, installs, and per-server overrides.
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "williamboman/mason.nvim",
                lazy = false,
                config = true,
            },
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            { "j-hui/fidget.nvim", opts = {} },
        },
        config = function()
            local clangd = require("config.lsp.clangd")
            local keymap = require("util.keymap")
            local attach_group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })
            local highlight_group = vim.api.nvim_create_augroup("user-lsp-highlight", { clear = false })
            local detach_group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = false })
            local has_node = vim.fn.executable("node") == 1
            local has_npm = vim.fn.executable("npm") == 1

            vim.api.nvim_create_autocmd("LspAttach", {
                group = attach_group,
                callback = function(event)
                    local map = function(keys, func, desc, mode)
                        keymap.buffer_map(event.buf, mode or "n", keys, func, "LSP: " .. desc)
                    end

                    map("gd", require("fzf-lua").lsp_definitions, "[G]oto [D]efinition")
                    map("gr", require("fzf-lua").lsp_references, "[G]oto [R]eferences")
                    map("gI", require("fzf-lua").lsp_implementations, "[G]oto [I]mplementation")
                    map("<leader>D", require("fzf-lua").lsp_typedefs, "Type [D]efinition")
                    map("<leader>ws", require("fzf-lua").lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if not client then
                        return
                    end

                    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                        vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = event.buf })

                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_group,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_group,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_clear_autocmds({ group = detach_group, buffer = event.buf })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = detach_group,
                            buffer = event.buf,
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({
                                    group = highlight_group,
                                    buffer = event2.buf,
                                })
                            end,
                        })
                    end

                    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                        map("<leader>th", function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
                        end, "[T]oggle Inlay [H]ints")
                    end

                    clangd.on_attach(client, event.buf)
                end,
            })

            local capabilities = require("blink.cmp").get_lsp_capabilities()

            local servers = {
                clangd = clangd.server_config(),

                zls = {},
                bashls = {},
                nil_ls = {},
                taplo = {},
                sqls = {},

                basedpyright = {
                    settings = {
                        basedpyright = {
                            analysis = {
                                typeCheckingMode = "standard",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },

                kotlin_language_server = {},

                lua_ls = {
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                },
            }

            if has_node then
                servers.ts_ls = {
                    filetypes = {
                        "javascript",
                        "javascriptreact",
                    },
                    settings = {
                        javascript = {
                            suggest = {
                                completeJSDocs = true,
                            },
                            preferences = {
                                includePackageJsonAutoImports = "auto",
                            },
                        },
                    },
                }

                servers.html = {}
                servers.cssls = {}
                servers.jsonls = {}

                servers.eslint = {
                    filetypes = {
                        "javascript",
                        "javascriptreact",
                    },
                }

                servers.emmet_language_server = {
                    filetypes = {
                        "html",
                        "css",
                        "scss",
                        "javascript",
                        "javascriptreact",
                    },
                }
            end

            require("mason").setup()

            local ensure_installed = {
                "clangd",
                "rust_analyzer",
                "lua_ls",
                "zls",
                "basedpyright",
                "kotlin_language_server",
                "bashls",
                "nil",
                "taplo",
                "sqls",

                "stylua",
                "clang-format",
                "shfmt",
                "ktlint",
                "ruff",
                "shellcheck",
                "nixfmt",
                "jq",
            }

            if has_npm then
                vim.list_extend(ensure_installed, {
                    "ts_ls",
                    "html",
                    "cssls",
                    "emmet_language_server",
                    "eslint-lsp",
                    "json-lsp",
                    "prettierd",
                })
            end

            require("mason-tool-installer").setup({
                ensure_installed = ensure_installed,
            })

            require("mason-lspconfig").setup({
                automatic_enable = false,
            })

            for server_name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                vim.lsp.config(server_name, server)
                vim.lsp.enable(server_name)
            end
        end,
    },
}
