# Maps lua/plugins/*.lua onto nixpkgs.vimPlugins, replacing lazy.nvim.
# Loading is eager (no lazy-loading layer -- accepted tradeoff, see
# implementation plan), so every plugin here is just added to the
# runtimepath; the ones that need setup() get their (trimmed, wrapper-free)
# lua/plugins/*.lua file wired in as `config` via toLuaFile, following the
# pattern from vimjoyer/nvim-nix-video: `lua << EOF ... EOF`, sourced
# in-place right after the plugin loads.
{ pkgs }:
let
  toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  toLua = str: "lua << EOF\n${str}\nEOF\n";
  p = pkgs.vimPlugins;

  treesitterWithGrammars = p.nvim-treesitter.withPlugins (
    ps: with ps; [
      bash
      c
      cpp
      diff
      lua
      luadoc
      nix
      python
      query
      toml
      vim
      vimdoc
      rust
      ron
      sql
      zig
    ]
  );
in
[
  # Pure dependencies: other plugins require() these directly, nothing of
  # our own to configure.
  p.nvim-nio
  p.plenary-nvim
  p.nvim-web-devicons
  p.nui-nvim
  p.friendly-snippets
  p.vim-sleuth # no Lua config at all -- runs via its own plugin/sleuth.vim

  # Configured plugins.
  {
    plugin = p.blink-cmp;
    config = toLuaFile ../lua/plugins/blink-cmp.lua;
  }
  {
    plugin = p.lazydev-nvim;
    config = toLua "require('lazydev').setup({ library = { 'nvim-dap-ui' } })";
  }
  {
    plugin = p.fidget-nvim;
    config = toLua "require('fidget').setup({})";
  }
  {
    plugin = p.nvim-lspconfig;
    config = toLuaFile ../lua/plugins/lsp.lua;
  }
  {
    plugin = p.nvim-colorizer-lua;
    config = toLuaFile ../lua/plugins/colorizer.lua;
  }
  {
    plugin = p.vague-nvim;
    config = toLuaFile ../lua/plugins/colorscheme.lua;
  }
  {
    plugin = p.conform-nvim;
    config = toLuaFile ../lua/plugins/conform.lua;
  }
  {
    plugin = p.crates-nvim;
    config = toLuaFile ../lua/plugins/crates.lua;
  }
  {
    plugin = p.nvim-dap;
    config = toLuaFile ../lua/plugins/debug.lua;
  }
  p.nvim-dap-ui
  p.nvim-dap-python
  p.nvim-dap-virtual-text
  {
    plugin = p.persistent-breakpoints-nvim;
    config = toLua "require('persistent-breakpoints').setup()";
  }
  {
    plugin = p.fzf-lua;
    config = toLuaFile ../lua/plugins/fzf-lua.lua;
  }
  {
    plugin = p.gitsigns-nvim;
    config = toLuaFile ../lua/plugins/gitsigns.lua;
  }
  {
    plugin = p.nvim-lint;
    config = toLuaFile ../lua/plugins/lint.lua;
  }
  {
    plugin = p.lualine-nvim;
    config = toLuaFile ../lua/plugins/lualine.lua;
  }
  {
    plugin = p.mini-nvim;
    config = toLuaFile ../lua/plugins/mini.lua;
  }
  {
    plugin = p.neotest;
    config = toLuaFile ../lua/plugins/neotest.lua;
  }
  p.neotest-python
  {
    plugin = p.neo-tree-nvim;
    config = toLuaFile ../lua/plugins/neo-tree.lua;
  }
  {
    plugin = p.nvim-notify;
    config = toLua "require('notify').setup({ stages = 'fade_in_slide_out', fps = 60, timeout = 500, render = 'minimal', top_down = false, background_colour = '#141415' })";
  }
  {
    plugin = p.noice-nvim;
    config = toLuaFile ../lua/plugins/noice.lua;
  }
  {
    plugin = p.rustaceanvim;
    config = toLuaFile ../lua/plugins/rustacean.lua;
  }
  {
    plugin = treesitterWithGrammars;
    config = toLuaFile ../lua/plugins/treesitter.lua;
  }
  {
    plugin = p.trouble-nvim;
    config = toLuaFile ../lua/plugins/trouble.lua;
  }
  {
    plugin = p.which-key-nvim;
    config = toLuaFile ../lua/plugins/which-key.lua;
  }
]
