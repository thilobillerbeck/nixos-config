{ config, pkgs, lib, ... }:
let
  sources = import ./../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in {
  imports = [
    ./zsh.nix
    ./packages-server.nix
    ./i18n.nix
    ./../users/root.nix
    ./../users/thilo.nix
    "${(import ./../nix/sources.nix).agenix}/modules/age.nix"
  ];

  # inspired by https://github.com/nix-community/srvos/blob/main/nixos/server/default.nix

  fonts.fontconfig.enable = lib.mkDefault false;
  sound.enable = false;

  nix = {
    optimise = {
      automatic = true;
      dates = [ "23:00" ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
    trustedUsers = [ "root" "thilo" ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 19999 ];
      allowedUDPPorts = [ 19999 ];
    };
    nameservers =
      [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
  };

  programs.mosh = { enable = true; };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "echo";
  };

  security.acme = {
    defaults.email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };

  virtualisation = {
    docker = {
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
        dates = "daily";
      };
      daemon.settings = { dns = config.networking.nameservers; };
    };
  };

  systemd = {
    watchdog = {
      runtimeTime = "20s";
      rebootTime = "30s";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  boot = {
    tmp.cleanOnBoot = lib.mkDefault true;
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  nixpkgs.config.allowUnfree = true;
}

