local options = {
	termguicolors = true, -- Keep colorschemes consistent with modern terminals.
	number = true, -- Anchor navigation with absolute line numbers.
	relativenumber = true, -- Make jump counts fast without losing position context.
	mouse = "a", -- Allow split resizing and scroll support when needed.
	showmode = false, -- Lualine already reports the current mode.
	cmdheight = 0,
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
	tabstop = 4,
	shiftwidth = 4,
	softtabstop = 4,
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

-- Defer clipboard setup so startup stays cheap in terminal-only sessions.
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

