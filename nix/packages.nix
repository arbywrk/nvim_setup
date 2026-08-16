# LSP servers, formatters, and linters, replacing what mason-tool-installer
# used to fetch at runtime. Debug adapters and the embedded toolchain
# (codelldb, cpptools, arm-none-eabi-gdb, openocd, ...) are pulled in
# separately -- see debug-packages.nix -- since a couple of those needed
# their own build spike before trusting them here.
{ pkgs }:
with pkgs;
[
  # C/C++
  clang-tools

  # Rust
  rust-analyzer

  # Lua
  lua-language-server
  stylua

  # Zig
  zls

  # Python
  basedpyright
  ruff

  # Bash
  bash-language-server
  shfmt
  shellcheck

  # Nix
  nil
  nixfmt

  # TOML / SQL / misc
  taplo
  sqls
  jq
]
