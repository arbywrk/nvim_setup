return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = {
		filetypes = {
			"*",
		},
	},
	-- if it does not work to start it manually run: :ColorizerAttachToBuffer
}
