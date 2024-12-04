{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
  prometheus_hosts = [
    "bart"
    "burns"
    "krusty"
    "lisa"
    "marge"
    "skinner"
  ];
in
{
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.11";

  networking = {
    hostName = "skinner";
    firewall = {
      allowedTCPPorts = [ 22 80 443 9001 9002 ];
    };
    networkmanager.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
    };
  };

  services.openssh.settings.PermitRootLogin = lib.mkDefault "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJV+6nhr0UgPZyNw0Fz6+t8FTu0vIe4giAGBE9rVWPeA root@coolify" ];

  age.secrets.coolify-env.file = ../../private/secrets/coolify-env-file.age;
  systemd.services.coolify-prepare-files = {
    description = "Setup files for coolify";
    wantedBy = [ "coolify.service" ];
    wants = [ "data-coolify.mount" ];
    script = ''
      #! ${pkgs.bash}/bin/bash
      NAMES='source ssh applications databases backups services proxy webhooks-during-maintenance ssh/keys ssh/mux proxy/dynamic'
      for NAME in $NAMES
      do
        FOLDER_PATH="/data/coolify/$NAME"
        if [ ! -d "$FOLDER_PATH" ]; then
          mkdir -p "$FOLDER_PATH"
        fi
      done

      cp -f "${./coolify/docker-compose.yml}" /data/coolify/source/docker-compose.yml
      cp -f "${./coolify/docker-compose.prod.yml}" /data/coolify/source/docker-compose.prod.yml
      cp -f "${ config.age.secrets.coolify-env.path }" /data/coolify/source/.env
      cp -f "${./coolify/upgrade.sh}" /data/coolify/source/upgrade.sh

      # Generate SSH key if not ready
      if [ ! -f "/data/coolify/ssh/keys/id.root@host.docker.internal" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -f /data/coolify/ssh/keys/id.root@host.docker.internal -t ed25519 -N "" -C root@coolify
      fi

      chown -R 9999:root /data/coolify
      chmod -R 700 /data/coolify
    '';
  };
  systemd.services.coolify = {
    script = ''
      APP_PORT="9999" "${pkgs.docker}/bin/docker" compose --env-file /data/coolify/source/.env -f /data/coolify/source/docker-compose.yml -f /data/coolify/source/docker-compose.prod.yml up -d --pull always --remove-orphans --force-recreate
    '';
    after = [ "docker.service" "docker.socket" ];
    wantedBy = [ "multi-user.target" ];
  };

  services = {
    gitea-actions-runner = {
      package = pkgs.forgejo-actions-runner;
      instances.skinner-secretary = {
        settings = {
          container = {
            network = "host";
          };
        };
        enable = true;
        name = config.networking.hostName;
        token = "";
        url = "https://git.thilo-billerbeck.com";
        labels = [
          "native:host"
          "debian-latest:docker://node:18-bullseye"
          "ubuntu-latest:docker://node:18-bullseye"
        ];
      };
    };
    prometheus = {
      enable = true;
      port = 9001;
      scrapeConfigs = lib.imap0 (i: v: {
        job_name = v;
        static_configs = [{
            targets = [ "${v}.thilo-billerbeck.com:9002" ];
        }];
      }) prometheus_hosts;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };
    };
  };
}
