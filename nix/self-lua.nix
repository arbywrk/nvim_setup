# Puts this repo's own non-plugin Lua modules (options.lua, keymaps.lua
# and lua/keymaps/*, lua/config/**, lua/util/*) on Neovim's runtimepath as
# a bare "plugin" with no config of its own, so require("options"),
# require("keymaps"), require("config.debug"), etc. resolve normally.
# lua/plugins/* is excluded -- those files are wired in individually via
# plugins.nix's toLuaFile instead, not require()'d.
{ pkgs }:
pkgs.runCommand "nvim-config-lua" { } ''
  mkdir -p $out/lua
  cp -r ${../lua}/. $out/lua/
  chmod -R u+w $out/lua
  rm -rf $out/lua/plugins
''
