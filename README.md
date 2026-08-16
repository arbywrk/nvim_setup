My nvim setup based on kickstart.nvim, packaged as a Nix flake.

Plugins, LSP servers, formatters, linters, and the embedded debug toolchain
are all managed declaratively via [home-manager](https://github.com/nix-community/home-manager) --
no lazy.nvim, no Mason, no runtime downloads. See:

- [doc/debugging.md](doc/debugging.md) for how project-local debugging targets work.
- `flake.nix` for what this exposes (`homeManagerModules.default`, a
  `smoke-test` build-only sanity check, and a devShell for hacking on this
  repo). Consume it from another flake via `inputs.nvim-config.url = "github:arbywrk/nvim_setup";`
  and import `homeManagerModules.default` into your home-manager config.

Working on this repo: `nix develop` gives you stylua/lua-language-server/ripgrep/fd.
Verify changes with `nix build .#homeConfigurations.smoke-test.activationPackage`.
