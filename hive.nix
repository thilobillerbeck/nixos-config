{ sources ? import ./nix/sources.nix }:

{
  meta = { nixpkgs = import sources.nixpkgs { }; };

  defaults = { pkgs, ... }: {
    deployment.buildOnTarget = true;
    deployment.allowLocalDeployment = true;
  };

  bart = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.pkgs = import sources.nixpkgs {
      system = "aarch64-linux";
    };
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };

  krusty = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.pkgs = import sources.nixpkgs { };
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };

  lisa = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.pkgs = import sources.nixpkgs { };
    networking = {
      hostName = name;
      domain = "thilo-billerbeck.com";
    };
  };

  burns = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.pkgs = import sources.nixpkgs {
      system = "aarch64-linux";
    };
    networking.hostName = name;
  };

  skinner = { name, nodes, pkgs, ... }: {
    imports = [ ./machines/${name}/configuration.nix ];
    deployment.targetHost = "${name}.thilo-billerbeck.com";
    nixpkgs.system = "aarch64-linux";
    nixpkgs.pkgs = import sources.nixpkgs {
      system = "aarch64-linux";
    };
    networking.hostName = name;
  };
}
