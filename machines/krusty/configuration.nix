{ config, pkgs, lib, ... }:
let
  invoiceninja_app = "invoiceninja";
  invoiceninja_domain = "invoiceninja.thilo-billerbeck.com";
  invoiceninja_dataDir = "/srv/http/${invoiceninja_domain}";
  sources = import ./../../nix/sources.nix;
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
        invoiceninja-db = {
          ports = [ "9999:3306" ];
          image = "mariadb";
          autoStart = true;
          volumes = [
            "/var/lib/invoiceninja/mariadb:/var/lib/mysql"
          ];
          extraOptions = [
            "--network=invoiceninja"
          ];
          environmentFiles = [
            /var/lib/secrets/invoiceninja.env
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

  systemd.services.invoicePocketbase = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "pocketbase";
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      LimitNOFILE = "4096";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = ''${unstable.pocketbase}/bin/pocketbase serve --http localhost:3456 --dir /var/lib/pb/invoiceapi/data --publicDir /var/lib/pb/invoiceapi/public'';
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
      phpEnv."PATH" = lib.makeBinPath [ pkgs.php82 pkgs.mysql ];
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
    cron = {
      enable = true;
      systemCronJobs = [
        "* * * * * cd /srv/http/${invoiceninja_domain} && ${pkgs.php82}/bin/php artisan schedule:run >> /dev/null 2>&1"
      ];
    };
  };
}
