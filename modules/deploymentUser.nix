{ lib, config, pkgs, ... }:

with lib;
let
  deploymentUserOptions = {
    deploymentPath = mkOption {
      type = types.path;
    };
    keys = mkOption {
      type = types.listOf types.str;
    };
  };
in
{
  options = {
    users.deploymentUsers = mkOption {
      default = { };
      type = with types; attrsOf (submodule [ { options = deploymentUserOptions; } ]);
    };
  };

  config = {
    users.groups = builtins.mapAttrs
      (name: group: { })
      config.users.deploymentUsers;

    users.users = builtins.mapAttrs
      (name: user: {
        description = "Deployment User ${name}";
        shell = pkgs.zsh;
        isNormalUser = true;
        packages = with pkgs; [
          openssh
        ];
        home = user.deploymentPath;
        openssh.authorizedKeys.keys = user.keys;
        group = "${name}";
        extraGroups = [ "docker" ];
        createHome = true;
      })
      config.users.deploymentUsers;
  };
}
