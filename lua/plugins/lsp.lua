return {
	{
		-- Extend Lua LSP with Neovim runtime types.
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types only when `vim.uv` is in play.
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
				"nvim-dap-ui",
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },
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
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local clangd = require("config.lsp.clangd")
			local attach_group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })
			local highlight_group = vim.api.nvim_create_augroup("user-lsp-highlight", { clear = false })
			local detach_group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = false })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = attach_group,
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end

					if client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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
								vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = event2.buf })
							end,
						})
					end

					if client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
					clangd.on_attach(client, event.buf)
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
			local clangd_servers = clangd.server_configs(vim.lsp.config.clangd)

			local servers = {
				gopls = {
					settings = {
						gopls = {
							analyses = {
								unusedparams = true,
							},
							staticcheck = true,
							gofumpt = true,
						},
					},
				},

				clangd = clangd_servers.clangd,
				esp_clangd = clangd_servers.esp_clangd,
				ts_ls = {},

				rust_analyzer = {
					settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
							},
							checkOnSave = {
								command = "clippy",
							},
						},
					},
				},

				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},
			}

			require("mason").setup()

			local ensure_installed = {
				"gopls",
				"clangd",
				"ts_ls",
				"rust_analyzer",
				"lua_ls",
			}
			vim.list_extend(ensure_installed, {
				"stylua",
				"clang-format",
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- Disable Mason's automatic vim.lsp.enable path so our custom configs win.
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
