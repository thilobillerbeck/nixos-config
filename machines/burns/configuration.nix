# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  fqdn = let
    join = domain: "matrix" + lib.optionalString (domain != null) ".${domain}";
  in join config.networking.domain;
  vaultwarden-domain = "vw.thilo-billerbeck.com";
  unstable =  import sources.unstable { config.allowUnfree = true; };
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ./../../modules/mautrix-whatsapp.nix
    ./../../modules/colmena-upgrade.nix
    ./../../configs/server.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "21.11";

  system.colmenaAutoUpgrade = {
    enable = true;
  };

  networking = {
    usePredictableInterfaceNames = false;
    hostName = "burns";
    domain = "avocadoom.de";
    enableIPv6 = true;
    firewall.allowedTCPPorts = [ 80 443 ];
    interfaces.eth0.ipv6.addresses = [{
      address = "2a01:4f8:1c1b:1079::1";
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

          locations."= /.well-known/matrix/server".extraConfig = let
            # use 443 instead of the default 8448 port to unite
            # the client-server and server-server port for simplicity
            server = { "m.server" = "${fqdn}:443"; };
          in ''
            add_header Content-Type application/json;
            return 200 '${builtins.toJSON server}';
          '';
          locations."= /.well-known/matrix/client".extraConfig = let
            client = {
              "m.homeserver" = { "base_url" = "https://${fqdn}"; };
              "m.identity_server" = { "base_url" = "https://vector.im"; };
            };
            # ACAO required to allow element-web on any URL to request this json file
          in ''
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '${builtins.toJSON client}';
          '';
        };

        # Reverse proxy for Matrix client-server and server-server communication
        ${fqdn} = {
          enableACME = true;
          forceSSL = true;

          # Or do a redirect instead of the 404, or whatever is appropriate for you.
          # But do not put a Matrix Web client here! See the Element web section below.
          locations."/".extraConfig = ''
            return 404;
          '';

          # locations."/synapse-admin/".root = unstable.synapse-admin;

          # forward all Matrix API calls to the synapse Matrix homeserver
          locations."/_matrix" = {
            proxyPass = "http://[::1]:8008"; # without a trailing /
          };
        };
        "${vaultwarden-domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${
                toString config.services.vaultwarden.config.ROCKET_PORT
              }";
          };
        };
      };
    };
    heisenbridge = {
      enable = true;
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
    };
    mautrix-whatsapp = {
      enable = false;
      environmentFile = pkgs.emptyFile;
      settings = {
        homeserver = {
          address = "http://localhost:8008";
          domain = "avocadoom.de";
          async_media = false;
        };
        bridge = {
          displayname_template =
            "{{ if .FullName }} {{ .FullName }} {{ else if .PushName}}{{.PushName}}{{else if .BusinessName}}{{.BusinessName}}{{else}}{{.JID}}{{end}} (WA)";
          personal_filtering_spaces = true;
          delivery_receipts = true;
          hystory_sync = {
            backfill = true;
            request_full_sync = true;
          };
          send_presence_on_typing = true;
          double_puppet_server_map = { };
          login_shared_secret_map = { };
          private_chat_portal_meta = true;
          mute_bridging = true;
          pinned_tag = "m.favourite";
          archive_tag = "m.lowpriority";
          enable_status_broadcast = false;
          allow_user_invite = true;
          disappearing_messages_in_groups = true;
          url_previews = true;
          encryption = { allow = true; };
          permissions = { "@avocadoom:avocadoom.de" = "admin"; };
        };
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
    netdata = {
      enable = true;
      package = unstable.netdata;
    };
  };
}
