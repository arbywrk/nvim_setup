# Home-manager module for this Neovim config. Touches only home-manager's
# own option namespace (programs.neovim, home.packages) -- never anything
# NixOS-only -- so it works identically whether imported inside a NixOS
# system's home-manager.users.<user>.imports, or via standalone
# home-manager on any other Linux distro.
#
# Deliberately does NOT set home.username/home.homeDirectory/home.stateVersion:
# those are machine/user-specific and belong in the consuming config, not
# in a reusable module.
{ pkgs, ... }:
{
  programs.neovim.enable = true;
}
