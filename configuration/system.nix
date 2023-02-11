{ lib, config, pkgs, inputs, ... }:
{
  boot = {
    loader.timeout = 0;
    loader.systemd-boot.enable = true;
    kernelPackages = pkgs.linuxPackages_zen;
  };

  zramSwap.enable = true;
  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users = {
      root.openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];
      default = {
        openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];
        name = "name_snrl";
        hashedPassword =
          "$6$6US0iMDXE1K7wj9g$2/JKHfX4VfNETELdt4dTlTUzlmZAmvP4XfRNB5ORVPYNmi6.A4EWpSXkpx/5PrPx1J/LaA41n2NDss/R0Utqh/";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    };
  };

  programs = {
    nano.syntaxHighlight = false;
    less.enable = lib.mkForce false;

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

    shellAliases = lib.mkForce {
      nboot = "nixos-rebuild boot --use-remote-sudo --fast --flake ~/learn_nix_flake/configuration";
      nswitch = "nixos-rebuild switch --use-remote-sudo --fast --flake ~/learn_nix_flake/configuration";
      nbuild = "nix build ~/learn_nix_flake/configuration";
      nupdate = "nix flake update --commit-lock-file ~/learn_nix_flake/configuration";
      nlock = "nix flake lock --commit-lock-file ~/learn_nix_flake/configuration";
    };

    defaultPackages = [ rsync perl ];

    systemPackages = [
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
      fzf
      zoxide
      tokei
      tealdeer
    ];
  };

  system.stateVersion = "22.11";
}
