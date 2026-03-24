-- Set leaders before plugins load so mappings stay predictable.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable icon-heavy plugins when the terminal font can render them.
vim.g.have_nerd_font = true

-- Keep core editor behavior separate from plugin setup.
require("options")

require("keymaps")
require("lazy-bootstrap")

require("lazy-plugins")

-- vim: ts=2 sts=2 sw=2 et
