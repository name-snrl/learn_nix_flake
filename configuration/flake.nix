{
  description = "simple nixos config";

  inputs = {
    main.url = "github:name-snrl/nixos-configuration";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvimpager.url = "github:lucc/nvimpager";
    nvim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    hw-config = {
      url = "file:///etc/nixos/hardware-configuration.nix";
      flake = false;
    };
    ssh-keys = {
      url = "https://github.com/name-snrl.keys";
      flake = false;
    };
    bash-fzf-completion = {
      url = "github:lincheney/fzf-tab-completion";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, main, ... }: {

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs.inputs = inputs;
      modules = [

        (import inputs.hw-config)

        main.nixosModules.global_variables
        main.nixosProfiles.bash
        main.nixosProfiles.git
        main.nixosProfiles.starship

        ({ lib, config, pkgs, inputs, ... }:

        {
          boot = {
            loader = {
              efi.canTouchEfiVariables = false;
              timeout = 3;
              systemd-boot = {
                enable = true;
                configurationLimit = 20;
                consoleMode = "max";
              };
            };

            kernelPackages = pkgs.linuxPackages_zen;
          };

          nix.registry.nixpkgs.flake = inputs.nixpkgs;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

          environment.shellAliases = {
            sudo = "sudo "; # this will make sudo work with shell aliases/man alias
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

          nixpkgs = {
            # Neovim overlay
            overlays = [
              inputs.nvim-nightly.overlay
              inputs.nvimpager.overlay

              (final: prev: {
                nvimpager = prev.nvimpager.overrideAttrs (oa: {
                  preBuild = ''
                    version=$(bash ./nvimpager -v | sed 's/.* //')
                    substituteInPlace nvimpager --replace '/nvimpager/init.vim' '/nvim/pager_init.lua'
                  '';
                });
              })
            ];

            # Allow unfree pkgs
            config = { allowUnfree = true; };
          };

          programs = {
            neovim = {
              enable = true;
              package = pkgs.neovim-nightly;
              defaultEditor = true;
              vimAlias = true;
              viAlias = true;
              configure.customRC = ''
                luafile $HOME/.config/nvim/init.lua
              '';
            };

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

          environment.systemPackages = with pkgs; [
            pciutils
            usbutils
            inetutils
            nixos-option

            # code
            gnumake gcc
            python310 python310Packages.python-lsp-server
            shellcheck nodePackages.bash-language-server
            rnix-lsp
            sumneko-lua-language-server
            ltex-ls

            # utilities
            (pkgs.runCommand "less" {} ''
              mkdir -p "$out/bin"
              ln -sfn "${pkgs.nvimpager}/bin/nvimpager" "$out/bin/less"
            '')
            difftastic
            tokei
            tealdeer
            file tree
            fzf
            (pkgs.runCommand "jq" {} ''
              mkdir -p "$out/bin"
              ln -sfn "${pkgs.gojq}/bin/gojq" "$out/bin/jq"
            '') # use gojq as jq
            jshon
            wget
            gptfdisk
            unzip

            # GNU replacement
            exa fd bat
            ripgrep
            zoxide
          ];

          system.stateVersion = "22.11";
        })
      ];
    };

  };
}
