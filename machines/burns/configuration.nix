# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  fqdn =
    let
      join = domain: "matrix" + lib.optionalString (domain != null) ".${domain}";
    in
    join config.networking.domain;
  vaultwarden-domain = "vw.thilo-billerbeck.com";
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    ./../../modules/colmena-upgrade.nix
    ./../../configs/server.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "21.11";

  networking = {
    usePredictableInterfaceNames = false;
    hostName = "burns";
    domain = "avocadoom.de";
    enableIPv6 = true;
    firewall.allowedTCPPorts = [ 80 443 8009 9002 ];
    interfaces.eth0.ipv6.addresses = [{
      address = "2a01:4f8:c17:552a::1";
      prefixLength = 64;
    }];
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
  };

  age.secrets = {
    vaultwardenConfigEnv = {
      file = ./../../secrets/vaultwardenConfigEnv.age;
      owner = "vaultwarden";
      group = "vaultwarden";
    };
    burnsBackupEnv = { file = ./../../secrets/burnsBackupEnv.age; };
    resticBackupPassword = { file = ./../../secrets/resticBackupPassword.age; };
  };

  services = {
    postgresql = {
      enable = true;
      initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      '';
    };
    nginx = {
      enable = true;
      # only recommendedProxySettings and recommendedGzipSettings are strictly required,
      # but the rest make sense as well
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts = {
        # This host section can be placed on a different host than the rest,
        # i.e. to delegate from the host being accessible as ${config.networking.domain}
        # to another host actually running the Matrix homeserver.
        "${config.networking.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."= /.well-known/matrix/server".extraConfig =
            let
              # use 443 instead of the default 8448 port to unite
              # the client-server and server-server port for simplicity
              server = {
                "m.server" = "${fqdn}:443";
              };
            in
            ''
              add_header Content-Type application/json;
              return 200 '${builtins.toJSON server}';
            '';
          locations."= /.well-known/matrix/client".extraConfig =
            let
              client = {
                "m.homeserver" = { "base_url" = "https://${fqdn}"; };
                "m.identity_server" = { "base_url" = "https://vector.im"; };
                "org.matrix.msc3575.proxy" = {
                  "url" = "https://${fqdn}";
                };
              };
              # ACAO required to allow element-web on any URL to request this json file
            in
            ''
              add_header Content-Type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '${builtins.toJSON client}';
            '';
        };
        ${fqdn} = {
          enableACME = true;
          forceSSL = true;
          locations."/".extraConfig = ''
            return 404;
          '';
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

            location ~* ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync) {
              proxy_pass http://127.0.0.1:8009;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Server $host;
            }

            location ~* ^(\/_matrix|\/_synapse\/client) {
              proxy_pass http://127.0.0.1:8008;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Server $host;

              client_max_body_size 50m;
              proxy_force_ranges on;
            }
          '';
        };
        "${vaultwarden-domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
          };
        };
        "the-lounge.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.thelounge.port}";
          };
        };
      };
    };
    heisenbridge = {
      enable = false;
      debug = true;
      package = unstable.heisenbridge;
      homeserver = "http://localhost:8008";
      owner = "@avocadoom:avocadoom.de";
    };
    matrix-synapse = {
      enable = true;
      settings.server_name = config.networking.domain;
      settings.listeners = [{
        port = 8008;
        # bind_address = "";
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" "federation" ];
          compress = false;
        }];
      }];
      settings.app_service_config_files =
        [ "/var/lib/heisenbridge/registration.yml" ];
      sliding-sync = {
        enable = true;
        settings = {
          SYNCV3_SERVER = "https://${fqdn}";
          SYNCV3_BINDADDR = "127.0.0.1:8009";
        };
        environmentFile = "/var/lib/matrix-synapse/SYNCV3_ENV";
      };
    };
    vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      backupDir = "/var/lib/vaultwarden/backups";
      environmentFile = config.age.secrets.vaultwardenConfigEnv.path;
      config = {
        DOMAIN = "https://${vaultwarden-domain}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";
        SMTP_HOST = "mail.officerent.de";
        SMTP_PORT = 587;
        SMTP_SECURITY = "starttls";
        SMTP_FROM = "vw@officerent.de";
        SMTP_FROM_NAME = "vw.thilo-billerbeck.com";
        SMTP_AUTH_MECHANIS = "Login";
        SMTP_ACCEPT_INVALID_HOSTNAMES = true;
        SMTP_ACCEPT_INVALID_CERTS = true;
      };
    };
    restic.backups.burns = {
      initialize = true;
      passwordFile = config.age.secrets.resticBackupPassword.path;
      environmentFile = config.age.secrets.burnsBackupEnv.path;
      paths = [
        "/var/lib/vaultwarden/backups"
        "/var/lib/matrix-synapse/homeserver.signing.key"
        "/var/lib/heisenbridge/registration.yml"
      ];
      repository = "b2:backup-burns";
      timerConfig = { OnCalendar = "*-*-* 3:00:00"; };
      pruneOpts = [ "--keep-daily 5" ];
    };
    thelounge = {
      enable = false;
      port = 7575;
      extraConfig = {
        reverseProxy = true;
        theme = "thelounge-theme-abyss";
      };
      plugins = [
        pkgs.nodePackages.thelounge-theme-abyss
      ];
    };
    prometheus = {
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
