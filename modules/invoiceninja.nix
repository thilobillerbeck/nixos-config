# from https://github.com/tecosaur/golgi
{ config, lib, pkgs, ... }:

with lib;

let
  invoiceninja_php = pkgs.php.buildEnv {
    extensions = { enabled, all }: with all; enabled ++ [ memcached ];
    extraConfig = ''
      memory_limit = 512M
    '';
  };
  invoiceninja_app_name = "invoiceninja";
  cfg = config.services.invoiceninja;
in {
  options = {
    services.invoiceninja = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc "Enable invoiceninja.";
      };

      domain = mkOption {
        type = types.str;
        description =
          lib.mdDoc "Domain name of the invoiceninja.";
      };

      path = mkOption {
        type = types.path;
        default = "/srv/http/${cfg.domain}";
        description =
          lib.mdDoc "User account under which woodpecker agent runs.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services."${invoiceninja_app_name}-scheduler" = {
      description = "${invoiceninja_app_name} scheduler";
      startAt = "minutely";

      unitConfig = {
        ConditionPathExists = "${cfg.path}/.env";
        ConditionDirectoryNotEmpty = "${cfg.path}/vendor";
      };

      serviceConfig = {
        Type = "oneshot";
        User = config.services.nginx.user;
        Group = config.services.nginx.user;
        SyslogIdentifier = "${invoiceninja_app_name}-scheduler";
        WorkingDirectory = "${cfg.path}";
        ExecStart = "${invoiceninja_php}/bin/php artisan schedule:run -v";
      };
    };
    services = {
      phpfpm.pools."${invoiceninja_app_name}" = {
        user = config.services.nginx.user;
        phpPackage = invoiceninja_php;
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
        phpEnv."PATH" = lib.makeBinPath [ invoiceninja_php pkgs.mysql ];
      };
      nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts = {
          "${cfg.domain}" = {
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              server_name ${cfg.domain};
              root ${cfg.path}/public;
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
                fastcgi_pass unix:${config.services.phpfpm.pools.${invoiceninja_app_name}.socket};
              }

              location ~ /\.ht {
                  deny all;
              }
            '';
          };
        };
      };
      mysql = {
        enable = true;
        dataDir = "/var/lib/mariadb";
        package = pkgs.mariadb;
      };
    };
  };
}
