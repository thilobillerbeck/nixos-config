# from https://github.com/tecosaur/golgi
{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.gitea-runner;
in {
  options = {
    services.gitea-runner = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc "Enable Gitea Runner.";
      };

      package = mkOption {
        type = types.package;
      };

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/gitea-runner";
      };

      user = mkOption {
        type = types.str;
        default = "gitea-runner";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.gitea-runner = {
      description = "gitea-runner";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "gitea-runner";
        ExecStart = "${cfg.package}/bin/act_runner daemon";
        WorkingDirectory = cfg.stateDir;
        Restart = "always";
      };
    };

    users.users = mkIf (cfg.user == "gitea-runner") {
      gitea-runner = {
        createHome = true;
        home = cfg.stateDir;
        useDefaultShell = true;
        group = "gitea-runner";
        extraGroups = [ "gitea" "docker" ];
        isSystemUser = true;
      };
    };
    users.groups.gitea-runner = {  };
  };
}