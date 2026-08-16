# Home-manager module for this Neovim config. Touches only home-manager's
# own option namespace (programs.neovim, home.packages) -- never anything
# NixOS-only -- so it works identically whether imported inside a NixOS
# system's home-manager.users.<user>.imports, or via standalone
# home-manager on any other Linux distro.
#
# Deliberately does NOT set home.username/home.homeDirectory/home.stateVersion:
# those are machine/user-specific and belong in the consuming config, not
# in a reusable module.
{ pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = import ./plugins.nix { inherit pkgs; } ++ [
      (import ./self-lua.nix { inherit pkgs; })
    ];

    # Mirrors init.lua: leaders set before anything else, then the two
    # non-plugin config modules. home-manager places the "advised plugin
    # config" (which sources every plugins.*.config string) at
    # lib.mkOrder 200 inside initLua; without an explicit lower mkOrder
    # here, this content gets the default priority (1000) and ends up
    # concatenated *after* that -- meaning every plugin's <leader>
    # keymaps would bind against the default "\" leader, not this one.
    # Verified against the actual generated init.lua after this fix.
    initLua = lib.mkOrder 100 ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      vim.g.have_nerd_font = true

      require("options")
      require("keymaps")
    '';
  };

  home.packages = (import ./packages.nix { inherit pkgs; }) ++ (import ./debug-packages.nix { inherit pkgs; });
}
