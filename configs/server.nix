{ config, pkgs, ... }:
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
    "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"}/modules/age.nix"
    ];

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
      dates = "daily";
    };
    optimise.automatic = true;
    trustedUsers = [ "root" "thilo" ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 19999 ];
      allowedUDPPorts = [ 19999 ];
    };
    nameservers = [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
  };

  programs.mosh = { enable = true; };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "yes";
    };
    journald.extraConfig = "SystemMaxUse=500M";
    timesyncd.enable = true;
    netdata = {
      enable = true;
      package = unstable.netdata;
    };
  };

  environment.variables.EDITOR = "nvim";

  security.acme = {
    defaults.email = "thilo.billerbeck@officerent.de";
    acceptTerms = true;
  };

  virtualisation = {
    docker = {
      autoPrune.enable = true;
      daemon.settings = {
        dns = config.networking.nameservers;
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
}

