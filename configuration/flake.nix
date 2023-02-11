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

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        pkgs = pkgsFor system;
        specialArgs = { inherit inputs; };
        modules = [

          (import inputs.hw-config)

          main.nixosModules.global_variables

          main.nixosProfiles.fish
          main.nixosProfiles.git
          main.nixosProfiles.nix
          main.nixosProfiles.starship

          ({ lib, config, pkgs, inputs, ... }:

            {
              boot = {
                loader = {
                  efi.canTouchEfiVariables = false;
                  timeout = 0;
                  systemd-boot = {
                    enable = true;
                    configurationLimit = 20;
                    consoleMode = "max";
                  };
                };

                kernelPackages = pkgs.linuxPackages_zen;
              };

              i18n.defaultLocale = "en_GB.UTF-8";
              time = {
                timeZone = "Asia/Yekaterinburg";
                hardwareClockInLocalTime = true;
              };

              console = {
                font = "Lat2-Terminus16";
                keyMap = "us";
                colors = [
                  "2e3440"
                  "d36265"
                  "88ce7c"
                  "e7e18c"
                  "5297cf"
                  "bf6ea3"
                  "5baebf"
                  "cad8e8"
                  "3b4252"
                  "ec6e71"
                  "a1f493"
                  "fff796"
                  "74b8ef"
                  "e28ec5"
                  "85d1e2"
                  "dfeaf5"
                ];
              };

              services.openssh.enable = true;
              users.users.root.openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];

              programs = {

                nano.syntaxHighlight = false;
                less.enable = lib.mkForce false;

                tmux = {
                  enable = true;
                  keyMode = "vi";
                };

                htop = {
                  enable = true;
                  settings = {
                    column_meters_0 = "System DateTime Uptime LoadAverage Tasks Blank Swap Memory";
                    column_meter_modes_0 = "2 2 2 2 2 2 2 2";
                    column_meters_1 = "AllCPUs DiskIO NetworkIO Blank Blank";
                    column_meter_modes_1 = "1 1 1 2 2";

                    fields = "4 0 48 17 18 46 39 2 49 1";
                    tree_view = 1;
                    tree_sort_key = 39;
                    tree_sort_direction = -1;
                    hide_kernel_threads = 1;
                    hide_userland_threads = 1;
                    show_program_path = 0;
                    highlight_base_name = 1;
                    show_cpu_frequency = 1;
                    cpu_count_from_one = 1;
                    color_scheme = 6;

                    "screen:Mem" = ''
                      PGRP PID USER M_VIRT M_SHARE M_RESIDENT M_SWAP Command
                      .sort_key=M_RESIDENT
                      .tree_sort_key=M_RESIDENT
                      .tree_view=1
                      .sort_direction=-1
                      .tree_sort_direction=-1
                    '';
                  };
                };
              };

              environment = with pkgs; {

                shellAliases = {
                  # NixOS
                  nboot = "sudo nixos-rebuild boot --flake ~/learn_nix_flake/configuration";
                  nswitch = "sudo nixos-rebuild switch --flake ~/learn_nix_flake/configuration";
                  nupdate = "nix flake update ~/learn_nix_flake/configuration";
                  nlock = "nix flake lock ~/learn_nix_flake/configuration";
                  nclear = "sudo nix-collect-garbage --delete-old";

                  # system
                  sudo = "sudo ";
                  sctl = "systemctl";
                  grep = "grep -E";
                  sed = "sed -E";

                  # misc
                  se = "sudoedit";
                  pg = "$PAGER";
                  ls = "exa";
                  rg = "rg --follow --hidden --smart-case --no-messages";
                  fd = "fd --follow --hidden";
                  dt = "difft";
                  tk = "tokei";
                  cat = "bat --pager=never --style=changes,rule,numbers,snip";
                };

                defaultPackages = [ rsync perl ];

                systemPackages = [
                  # system shit
                  pciutils
                  usbutils
                  inetutils

                  # base
                  nvim.mini
                  nvimpager
                  difftastic
                  gojq-as-jq
                  ripgrep
                  fd
                  exa
                  bat
                  file
                  tree
                  wget

                  # cli
                  et
                  fzf # for zoxide/fzf-bash-complete
                  zoxide
                  tokei
                  tealdeer
                ];
              };

              system.stateVersion = "22.11";
            })
        ];
      };

    };
}
