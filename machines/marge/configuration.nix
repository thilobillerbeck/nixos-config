{ config, pkgs, lib, ... }:

let
  mailcowDir = "/opt/mailcow-dockerized";
  matrix_domain = "avocadoom.de";
  matrix_fqdn =
    let
      join = domain: "matrix" + lib.optionalString (domain != null) ".${domain}";
    in
    join matrix_domain;
in {
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.05";

  networking = {
    hostName = "marge";
    nameservers = [ "8.8.8.8" ];
    defaultGateway = "172.31.1.1";
    firewall = { allowedTCPPorts = [ 22 25 80 110 143 443 465 587 993 995 4190 9002 ]; };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    nat = {
      enable = true;
      enableIPv6 = true;
      internalIPs = [
        "100.67.152.0/24"
      ];
      internalIPv6s = [
        "fd7a:115c:a1e0::/48"
      ];
      externalInterface = "eth0";
      externalIP = "116.203.63.1";
      externalIPv6 = "2a01:4f8:1c1c:761c::1";
    };
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="116.203.63.1"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:1c1c:761c::1"; prefixLength=64; }
          /* { address="fe80::9400:2ff:fe96:594d"; prefixLength=64; } */
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="96:00:02:96:59:4d", NAME="eth0"
  '';

  age.secrets = {
    burnsBackupEnv = { file = ./../../private/secrets/burnsBackupEnv.age; };
    resticBackupPassword = { file = ./../../private/secrets/resticBackupPassword.age; };
    vaultwardenConfigEnv = { file = ./../../private/secrets/vaultwardenConfigEnv.age; };
  };

  virtualisation = {
    docker = { enable = true; };
  };

  services = {
    # nginx mailcow
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "mail.officerent.de" = {
          serverAliases = [
            "autodiscover.thilo-billerbeck.com"
            "autoconfig.thilo-billerbeck.com"
            "autodiscover.officerent.de"
            "autoconfig.officerent.de"
          ];
          enableACME = true;
          forceSSL = true;
          locations."/Microsoft-Server-ActiveSync".proxyPass =
            "http://127.0.0.1:8080/Microsoft-Server-ActiveSync";
          locations."/".proxyPass = 
            "http://127.0.0.1:8080/";
        };
        "bitwarden.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
          };
        };
        # This host section can be placed on a different host than the rest,
        # i.e. to delegate from the host being accessible as ${config.networking.domain}
        # to another host actually running the Matrix homeserver.
        "${matrix_domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."= /.well-known/matrix/server".extraConfig =
            let
              # use 443 instead of the default 8448 port to unite
              # the client-server and server-server port for simplicity
              server = {
                "m.server" = "${matrix_fqdn}:443";
              };
            in
            ''
              add_header Content-Type application/json;
              return 200 '${builtins.toJSON server}';
            '';
          locations."= /.well-known/matrix/client".extraConfig =
            let
              client = {
                "m.homeserver" = { "base_url" = "https://${matrix_fqdn}"; };
                "m.identity_server" = { "base_url" = "https://vector.im"; };
                "org.matrix.msc3575.proxy" = {
                  "url" = "https://${matrix_fqdn}";
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
        ${matrix_fqdn} = {
          enableACME = true;
          forceSSL = true;
          locations."/".extraConfig = ''
            return 404;
          '';
          extraConfig = ''
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

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
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "matrix-synapse" ];
      initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
      '';
    };

    matrix-synapse = {
      enable = true;
      settings.server_name = matrix_domain;
      settings.listeners = [{
        port = 8008;
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" "federation" ];
          compress = false;
        }];
      }];
    };

    vaultwarden = {
       enable = true;
       package = pkgs.vaultwarden;
       dbBackend = "sqlite";
       backupDir = "/var/lib/vaultwarden/backups";
       environmentFile = config.age.secrets.vaultwardenConfigEnv.path;
       config = {
         DOMAIN = "https://bitwarden.thilo-billerbeck.com";
         SIGNUPS_ALLOWED = false;
         ROCKET_ADDRESS = "127.0.0.1";
         ROCKET_PORT = 8234;
         ROCKET_LOG = "critical";
         SMTP_HOST = "mail.officerent.de";
         SMTP_PORT = 587;
         SMTP_SECURITY = "starttls";
         SMTP_FROM = "vw@officerent.de";
         SMTP_FROM_NAME = "bitwarden.thilo-billerbeck.com";
         SMTP_AUTH_MECHANIS = "Login";
         SMTP_ACCEPT_INVALID_HOSTNAMES = true;
         SMTP_ACCEPT_INVALID_CERTS = true;
       };
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

    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      openFirewall = true;
      extraUpFlags = [
        "--advertise-exit-node"
        "--ssh"
      ];
    };

    restic.backups.burns = {
      initialize = false;
      passwordFile = config.age.secrets.resticBackupPassword.path;
      environmentFile = config.age.secrets.burnsBackupEnv.path;
      paths = [
        "/var/lib/matrix-synapse/homeserver.signing.key"
        "/var/lib/heisenbridge/registration.yml"
      ];
      repository = "b2:backup-burns";
      timerConfig = { OnCalendar = "*-*-* 3:00:00"; };
      pruneOpts = [ "--keep-daily 5" ];
    };
  };

  security.acme = {
    certs."mail.officerent.de" = {
      postRun = ''
        cp fullchain.pem /opt/mailcow-dockerized/data/assets/ssl/key.pem
        cp key.pem /opt/mailcow-dockerized/data/assets/ssl/key.pem
      '';
    };
  };
}
