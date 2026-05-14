return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
				"bash",
				"c",
				"cpp",
				"css",
				"diff",
				"html",
				"javascript",
				"json",
				"kotlin",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"rust",
				"ron",
				"zig",
			})
		end,
	},
}
