-- Set leaders before plugins load so mappings stay predictable.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable icon-heavy plugins when the terminal font can render them.
vim.g.have_nerd_font = true

-- Keep core editor behavior separate from plugin setup. Plugins and their
-- config are provided by the home-manager module (nix/hm-module.nix) --
-- see doc/debugging.md and flake.nix. This file only matters when Neovim
-- is invoked outside that wrapper (e.g. from within this repo's devShell).
require("options")
require("keymaps")
