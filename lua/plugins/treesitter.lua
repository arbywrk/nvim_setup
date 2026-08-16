-- Parsers are bundled at build time via nix/plugins.nix's
-- nvim-treesitter.withPlugins -- no runtime :TSInstall / .install() call
-- needed (or wanted: that would mean a network fetch at edit-time).
require("nvim-treesitter").setup()
