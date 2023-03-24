{ config, pkgs, lib, ... }:

{
  age.secrets = {
    watchtowerEnv = {
      file = ./../../secrets/watchtower-env.age;
    };
  };

  virtualisation = {
    oci-containers = {
      containers = {
        "watchtower" = {
          image = "containrrr/watchtower:latest";
          volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
          environmentFiles = [
            config.age.secrets.watchtowerEnv.path
          ];
        };
      };
    };
  };
}