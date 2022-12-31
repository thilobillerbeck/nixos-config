{
  meta = {
    nixpkgs = <nixpkgs>;
  };

  defaults = { pkgs, ... }: {
    deployment.buildOnTarget = true;
    deployment.allowLocalDeployment = true;

    nix.nixPath = [ "nixpkgs=channel:nixos-22.11" ];
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
}