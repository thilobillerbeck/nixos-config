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
  };
}