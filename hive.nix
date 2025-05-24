{ sources ? import ./nix/sources.nix }:

{
  meta = {
    nixpkgs = import sources.nixpkgs { };
    nodeNixpkgs = {
      bart = import sources.nixpkgs { system = "aarch64-linux"; };
      marge = import sources.nixpkgs { system = "aarch64-linux"; };
    };
  };

  defaults = { pkgs, ... }: {
    deployment.buildOnTarget = true;
    deployment.allowLocalDeployment = true;
  };

  bart = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };

  marge = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };
}
