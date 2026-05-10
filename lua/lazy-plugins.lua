require("lazy").setup({
	spec = {
		-- My plugins
		{ import = "plugins" },
	},

	defaults = {
		lazy = false, -- not lazy by default
		version = false, -- always use the latest version
	},

	checker = { enabled = true, notify = false }, -- plugin update checker
}, {
	ui = {
		icons = {
			cmd = " ",
			config = "",
			debug = "● ",
			event = " ",
			favorite = " ",
			ft = " ",
			init = " ",
			import = " ",
			keys = " ",
			lazy = "󰒲 ",
			loaded = "●",
			not_loaded = "○",
			plugin = " ",
			runtime = " ",
			require = "󰢱 ",
			source = " ",
			start = " ",
			task = "✔ ",
			list = {
				"●",
				"➜",
				"★",
				"‒",
			},
		},
	},
})
