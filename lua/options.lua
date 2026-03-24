local options = {
	termguicolors = true, -- Keep colorschemes consistent with modern terminals.
	number = true, -- Anchor navigation with absolute line numbers.
	relativenumber = true, -- Make jump counts fast without losing position context.
	mouse = "a", -- Allow split resizing and scroll support when needed.
	showmode = false, -- Lualine already reports the current mode.
	breakindent = true, -- Preserve indentation when wrapped text spills.
	undofile = true, -- Keep undo history across restarts.

	wrap = false,

	-- Stay forgiving for lowercase searches while preserving exact-match escapes.
	ignorecase = true,
	smartcase = true,

	-- Reserve the diagnostics column to avoid text shifting.
	signcolumn = "yes",

	-- Make diagnostics and CursorHold reactions feel snappier.
	updatetime = 250,

	-- Show which-key hints sooner without making mappings twitchy.
	timeoutlen = 300,

	-- Open new panes where they least disrupt the current layout.
	splitright = true,
	splitbelow = true,

	-- Surface stray whitespace without filling the screen with markers.
	list = true,
	listchars = { tab = "  ", trail = " ", nbsp = "␣" },
	tabstop = 2,
	shiftwidth = 2,
	softtabstop = 2,
	expandtab = true,

	-- Preview substitutions in a split before they are applied.
	inccommand = "split",

	-- Keep the active line easy to track.
	cursorline = true,

	-- Avoid parking the cursor against the screen edge.
	scrolloff = 10,
}

for k, v in pairs(options) do
	vim.opt[k] = v
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("user-c-style-defaults", { clear = true }),
	pattern = { "c", "cpp", "h", "hpp" },
	-- Default to two-space C-style indentation until a project formatter overrides it.
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.expandtab = true
	end,
})

-- Defer clipboard setup so startup stays cheap in terminal-only sessions.
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- vim: ts=2 sts=2 sw=2 et
