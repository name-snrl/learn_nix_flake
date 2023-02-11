{
  description = "simple nixos config";

  inputs = {
    main.url = "github:name-snrl/nixos-configuration";
    nixpkgs.follows = "main/nixpkgs";
    flake-registry.follows = "main/flake-registry";

    hw-config = {
      url = "file:///etc/nixos/hardware-configuration.nix";
      flake = false;
    };
    ssh-keys = {
      url = "https://github.com/name-snrl.keys";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, main, ... }:
    let
      pkgsFor = system:
        import inputs.nixpkgs {
          overlays = [ main.overlay ];
          localSystem = { inherit system; };
          config.allowUnfree = true;
        };
    in
    {
      legacyPackages.x86_64-linux = pkgsFor "x86_64-linux";

      packages.x86_64-linux.default = self.nixosConfigurations.nixos.config.system.build.toplevel;

      nixosModules.default = ./system.nix;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        pkgs = pkgsFor system;
        specialArgs = { inherit inputs; };
        modules = [
          self.nixosModules.default
          (import inputs.hw-config)

          main.nixosProfiles.fish
          main.nixosProfiles.aliases
          main.nixosProfiles.git
          main.nixosProfiles.nix
          main.nixosProfiles.starship
        ];
      };
    };
}
