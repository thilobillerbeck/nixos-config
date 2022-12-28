# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  fqdn = let
    join = domain:
      "matrix" + lib.optionalString (domain != null) ".${domain}";
  in join config.networking.domain;
  unstable = import <unstable> { };
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ./../../modules/mautrix-whatsapp.nix
    ./../../configs/server.nix
    ./../../users/thilo.nix
    ./../../users/root.nix
    (fetchTarball
      "https://github.com/msteen/nixos-vscode-server/tarball/master")
    # ./heisenbridge.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "21.11";

  networking = {
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    usePredictableInterfaceNames = false;
    hostName = "burns";
    domain = "avocadoom.de";
    firewall.allowedTCPPorts = [ 80 443 ];
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
    vscode-server.enable = true;
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
            server = { "m.server" = "${fqdn}\:443"; };
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
      # registration_shared_secret = "QmmgP1Gco31o3mMIft82j2VdKrSGlSIihgYfduZx8cR4eRHLmVEzWzCFpF3JDhWN";
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
        [
          "/var/lib/heisenbridge/registration.yml"
        ];
    };
    mautrix-whatsapp = {
      enable = true;
      environmentFile = pkgs.emptyFile;
      settings = {
        homeserver = {
          address = "http://localhost:8008";
          domain = "avocadoom.de";
          async_media = false;
        };
	      bridge = {
          displayname_template = "{{ if .FullName }} {{ .FullName }} {{ else if .PushName}}{{.PushName}}{{else if .BusinessName}}{{.BusinessName}}{{else}}{{.JID}}{{end}} (WA)";
          personal_filtering_spaces = true;
          delivery_receipts = true;
          hystory_sync = {
            backfill = true;
            request_full_sync = true;
          };
          send_presence_on_typing = true;
          double_puppet_server_map = {};
          login_shared_secret_map = {};
          private_chat_portal_meta = true;
          mute_bridging = true;
          pinned_tag = "m.favourite";
          archive_tag = "m.lowpriority";
          enable_status_broadcast = false;
          allow_user_invite = true;
          disappearing_messages_in_groups = true;
          url_previews = true;
          encryption = {
            allow = true;
          };
          permissions = {
            "@avocadoom:avocadoom.de" = "admin";
          };
        };
      };
    };
  };
}
