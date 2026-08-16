{
  description = "Neovim config as a home-manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeManagerModules.default = import ./nix/hm-module.nix;

      # Build-only sanity check that the module works via standalone
      # home-manager (not just as a NixOS-embedded module): `nix build
      # .#homeConfigurations.smoke-test.activationPackage` (or `home-manager
      # build --flake .#smoke-test`) should succeed without ever being
      # activated.
      homeConfigurations.smoke-test = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          self.homeManagerModules.default
          {
            home.username = "smoke-test";
            home.homeDirectory = "/home/smoke-test";
            home.stateVersion = "25.05";
          }
        ];
      };

      # Tooling for hacking on this repo itself (formatting, linting,
      # searching) -- replaces the old mise.toml now that the flake is the
      # single source of reproducible tooling.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          stylua
          lua-language-server
          ripgrep
          fd
        ];
      };
    };
}
