{ config, pkgs, lib, ... }:
let
  invoiceninja_app = "invoiceninja";
  invoiceninja_domain = "invoiceninja.thilo-billerbeck.com";
  invoiceninja_dataDir = "/srv/http/${invoiceninja_domain}";
  sources = import ./../../nix/sources.nix;
  invoiceninja_php = pkgs.php82.buildEnv { extraConfig = "memory_limit = 512M"; };
  unstable = import sources.unstable { config.allowUnfree = true; };
in
{
  imports = [
    ./../../configs/server.nix
    ./hardware.nix
    ./../../modules/colmena-upgrade.nix
    ./../../modules/containers/watchtower.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.05";

  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        "n8n" = {
          ports = [ "5678:5678" ];
          image = "n8nio/n8n:latest";
          volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
        };
        "directus" = {
          ports = [ "8055:8055" ];
          image = "directus/directus:latest";
          volumes = [
            "directus-database:/directus/database"
            "directus-uploads:/directus/uploads"
          ];
          environmentFiles = [
            /var/lib/directus/.env
          ];
        };
        "kimai-db" = {
          image = "mysql";
          volumes = [ "kimai-database:/var/lib/mysql" ];
          environmentFiles = [
            /var/lib/kimai/.env-db
          ];
          extraOptions = [
            "--network=kimai"
          ];
        };
        "kimai" = {
          ports = [ "8056:8001" ];
          image = "kimai/kimai2:apache";
          environmentFiles = [
            /var/lib/kimai/.env
          ];
          extraOptions = [
            "--network=kimai"
          ];
        };
      };
    };
    docker = { enable = true; };
  };

  networking = {
    hostName = "krusty";
    firewall = { allowedTCPPorts = [ 22 80 443 9001 8055 ]; };
  };

  systemd.timers."invoiceninja" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "invoiceninja.service";
    };
  };

  systemd.services."invoiceninja" = {
    script = ''
      cd /srv/http/${invoiceninja_domain}
      ${pkgs.php82}/bin/php artisan schedule:run
    '';
    serviceConfig = {
      Type = "oneshot";
      User = config.services.nginx.user;
    };
  };

  services = {
    phpfpm.pools.${invoiceninja_app} = {
      user = config.services.nginx.user;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
      phpEnv."PATH" = lib.makeBinPath [ pkgs.invoiceninja_php pkgs.mysql ];
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "n8n.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:5678";
        };
        "directus.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:8055";
        };
        "kimai.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:8056";
        };
        "${invoiceninja_domain}" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            server_name ${invoiceninja_domain};
            root ${invoiceninja_dataDir}/public;
            index index.php index.html index.htm;
            client_max_body_size 20M;

            gzip on;
            gzip_types      application/javascript application/x-javascript text/javascript text/plain application/xml application/json;
            gzip_proxied    no-cache no-store private expired auth;
            gzip_min_length 1000;

            location / {
                try_files $uri $uri/ =404;
            }

            location ~* \.pdf$ {
                add_header Cache-Control no-store;
            }

            if (!-e $request_filename) {
                rewrite ^(.+)$ /index.php?q= last;
            }

            location ~* /storage/.*\.php$ {
                return 503;
            }

            location ~ \.php$ {
              include ${pkgs.nginx}/conf/fastcgi.conf;
              fastcgi_pass unix:${config.services.phpfpm.pools.${invoiceninja_app}.socket};
            }

            location ~ /\.ht {
                deny all;
            }
          '';
        };
        "trilium.thilo-billerbeck.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.trilium-server.port}/";
            proxyWebsockets = true;
          };
        };
      };
    };
    trilium-server.enable = true;
    mysql = {
      enable = true;
      dataDir = "/var/lib/mariadb";
      package = pkgs.mariadb;
    };
  };
}
