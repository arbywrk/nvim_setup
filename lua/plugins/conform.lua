local prettierd = vim.fn.executable("node") == 1 and { "prettierd" } or {}
local json_formatter = vim.fn.executable("node") == 1 and { "prettierd" } or { "jq" }
local jsonc_formatter = vim.fn.executable("node") == 1 and { "prettierd" } or {}

return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				return {
					timeout_ms = 500,
					lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format" },
				zig = { "zig" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				kotlin = { "ktlint" },
				nix = { "nixfmt" },
				toml = { "taplo" },
				javascript = prettierd,
				javascriptreact = prettierd,
				html = prettierd,
				css = prettierd,
				scss = prettierd,
				json = json_formatter,
				jsonc = jsonc_formatter,
			},
		},
	},
}
