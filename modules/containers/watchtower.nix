{ config, pkgs, lib, ... }:

{
  age.secrets = {
    watchtowerEnv = { file = ./../../private/secrets/watchtower-env.age; };
  };

  virtualisation = {
    oci-containers = {
      containers = {
        "watchtower" = {
          image = "containrrr/watchtower:latest";
          volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
          environment = {
            WATCHTOWER_CLEANUP = "true";
            WATCHTOWER_POLL_INTERVAL = "3600";
            WATCHTOWER_NOTIFICATION_TEMPLATE = ''
              {{range .}}{{.Time.Format "2006-01-02 15:04:05"}} ({{.Level}}): {{.Message}}{{println}}{{end}}'';
            WATCHTOWER_NOTIFICATIONS_HOSTNAME = config.networking.hostName;
          };
          environmentFiles = [ config.age.secrets.watchtowerEnv.path ];
        };
      };
    };
  };
}
