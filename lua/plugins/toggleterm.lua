return {
	"akinsho/toggleterm.nvim",
	version = "*",
	opts = {
		size = function(term)
			if term.direction == "horizontal" then
				return 15
			elseif term.direction == "vertical" then
				return math.floor(vim.o.columns * 0.4)
			end
		end,
		float_opts = { border = "curved" },
		shade_terminals = false,
	},
	config = function(_, opts)
		require("toggleterm").setup(opts)

		-- Only normal-mode entry point: open/minimize the bottom panel (VS Code style)
		vim.keymap.set("n", "<C-`>", "<cmd>1ToggleTerm direction=horizontal<CR>", { desc = "Terminal: toggle panel" })

		-- Everything below is terminal-mode only ----------------------------

		-- Minimize the panel from inside it
		vim.keymap.set("t", "<C-`>", "<cmd>1ToggleTerm direction=horizontal<CR>", { desc = "Terminal: minimize panel" })

		-- Open a vertical split terminal alongside the current one
		vim.keymap.set("t", "<C-t>v", "<cmd>2ToggleTerm direction=vertical<CR>", { desc = "Terminal: toggle vertical" })

		-- Float/unfloat the focused terminal (no direct float spawn from normal mode)
		vim.keymap.set("t", "<C-f>", function()
			local id = vim.b.toggle_number
			if not id then return end
			local term = require("toggleterm.terminal").get(id)
			if not term then return end
			local new_dir = term.direction == "float" and "horizontal" or "float"
			term:close()
			term.direction = new_dir
			term:open()
		end, { desc = "Terminal: toggle float" })

		-- Reposition the terminal window — Ghostty sends distinct C-S-* via kitty protocol
		vim.keymap.set("t", "<C-S-h>", "<C-\\><C-n><C-w>H", { desc = "Terminal: move window left" })
		vim.keymap.set("t", "<C-S-j>", "<C-\\><C-n><C-w>J", { desc = "Terminal: move window down" })
		vim.keymap.set("t", "<C-S-k>", "<C-\\><C-n><C-w>K", { desc = "Terminal: move window up" })
		vim.keymap.set("t", "<C-S-l>", "<C-\\><C-n><C-w>L", { desc = "Terminal: move window right" })
	end,
}
