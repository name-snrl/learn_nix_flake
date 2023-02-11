{
  description = "Deployment for my servers";

  nixConfig = {
    extra-substituters = [ "https://colmena.cachix.org" ];
    extra-trusted-public-keys = [ "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg=" ];
  };

  inputs = {
    configuration.url = "../configuration";
    main.follows = "configuration/main";
    nixpkgs.follows = "configuration/nixpkgs";
    ssh-keys.follows = "configuration/ssh-keys";
    flake-registry.follows = "configuration/flake-registry";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = inputs@{ self, nixpkgs, main, colmena, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        overlays = [ main.overlay ];
        localSystem = { inherit system; };
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ colmena.defaultPackage.${system} ];
      };

      colmena = {
        meta = {
          nixpkgs = pkgs;
          specialArgs = { inherit inputs; };
        };

        nixos = { lib, config, pkgs, inputs, ... }:
          {
            deployment = {
              targetUser = "name_snrl";
              targetHost = "192.168.122.32";
            };

            imports = [
              inputs.configuration.nixosModules.default
              ./hw-config.nix

              inputs.main.nixosProfiles.fish
              inputs.main.nixosProfiles.aliases
              inputs.main.nixosProfiles.nix
              inputs.main.nixosProfiles.starship

              # add firefox for fun
              ({ pkgs, ... }: { environment.systemPackages = [ pkgs.firefox ]; })
            ];
          };

      };
    };
}
