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
			local attach_group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })
			local highlight_group = vim.api.nvim_create_augroup("user-lsp-highlight", { clear = false })
			local detach_group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = false })
			local svelte_group = vim.api.nvim_create_augroup("user-svelte-lsp", { clear = true })
			local svelte_change_notifier_registered = false
			local has_node = vim.fn.executable("node") == 1
			local has_npm = vim.fn.executable("npm") == 1

			local function register_svelte_change_notifier()
				if svelte_change_notifier_registered then
					return
				end

				svelte_change_notifier_registered = true
				vim.api.nvim_create_autocmd("BufWritePost", {
					group = svelte_group,
					pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.svelte" },
					callback = function(ctx)
						for _, svelte_client in ipairs(vim.lsp.get_clients({ name = "svelte" })) do
							svelte_client.notify("$/onDidChangeTsOrJsFile", {
								uri = vim.uri_from_fname(ctx.file),
							})
						end
					end,
				})
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = attach_group,
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("gd", require("fzf-lua").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("fzf-lua").lsp_references, "[G]oto [R]eferences")
					map("gI", require("fzf-lua").lsp_implementations, "[G]oto [I]mplementation")
					map("<leader>D", require("fzf-lua").lsp_typedefs, "Type [D]efinition")
					map("<leader>ds", require("fzf-lua").lsp_document_symbols, "[D]ocument [S]ymbols")
					map("<leader>ws", require("fzf-lua").lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")
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

					if client.name == "svelte" then
						register_svelte_change_notifier()
					end

					clangd.on_attach(client, event.buf)
				end,
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local clangd_servers = clangd.server_configs(vim.lsp.config.clangd)

			local servers = {
				clangd = clangd_servers.clangd,
				esp_clangd = clangd_servers.esp_clangd,
				zls = {},
				bashls = {},
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
				servers.ts_ls = {}
				servers.svelte = {
					settings = {
						svelte = {
							plugin = {
								svelte = {
									format = {
										enable = false,
									},
								},
							},
						},
					},
				}
				servers.html = {}
				servers.cssls = {}
				servers.eslint = {
					filetypes = {
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
						"svelte",
					},
				}
				servers.emmet_language_server = {
					filetypes = {
						"html", "css", "scss",
						"javascript", "javascriptreact",
						"typescript", "typescriptreact",
						"svelte",
					},
				}
			else
				vim.notify_once(
					"Node.js is not on PATH. Skipping TypeScript, HTML, CSS, ESLint, and Emmet LSP servers.",
					vim.log.levels.WARN
				)
			end

			require("mason").setup()

			local ensure_installed = {
				-- LSP servers
				"clangd",
				"ts_ls",
				"rust_analyzer",
				"lua_ls",
				"zls",
				"basedpyright",
				"kotlin_language_server",
				"bashls",
				-- Formatters / linters
				"stylua",
				"clang-format",
				"shfmt",
				"ktlint",
				"ruff",
				"shellcheck",
			}

			if has_npm then
				vim.list_extend(ensure_installed, {
					"ts_ls",
					"html",
					"cssls",
					"emmet_language_server",
					"svelte-language-server",
					"eslint-lsp",
					"prettierd",
				})
			else
				vim.notify_once(
					"npm is not on PATH. Skipping Mason installs for Svelte, ESLint, web LSPs, and prettierd.",
					vim.log.levels.WARN
				)
			end

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
