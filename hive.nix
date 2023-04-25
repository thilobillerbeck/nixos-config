{ sources ? import ./nix/sources.nix }:

{
  meta = {
    nixpkgs = import sources.nixpkgs {};
  };

  defaults = { pkgs, ... }: {
    deployment.buildOnTarget = true;
    deployment.allowLocalDeployment = true;

    nix.nixPath = [
      "nixpkgs=channel:nixos-22.11"
      "unstable=channel:nixos-unstable"
      ];
  };

  bart = { name, nodes, pkgs, ... }: { 
    imports = [ ./machines/${name}/configuration.nix ]; 
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };

  krusty = { name, nodes, pkgs, ... }: { 
    imports = [ ./machines/${name}/configuration.nix ]; 
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };
  
  lisa = { name, nodes, pkgs, ... }: { 
    imports = [ ./machines/${name}/configuration.nix ]; 
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };
  
  burns = { name, nodes, pkgs, ... }: { 
    imports = [ ./machines/${name}/configuration.nix ]; 
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking.hostName = name;
  };
  
  skinner = { name, nodes, pkgs, ... }: { 
    imports = [ ./machines/${name}/configuration.nix ]; 
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.system = "aarch64-linux";
    networking.hostName = name;
  };
}