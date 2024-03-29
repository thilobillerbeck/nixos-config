{ config, pkgs, ... }:

{
  users.groups.deploy = { };
  users.users.deploy = {
    uid = 1001;
    description = "Deployment User";
    shell = pkgs.zsh;
    isNormalUser = true;
    packages = with pkgs; [
      openssh
    ];
    openssh.authorizedKeys.keys = [
      # deploy
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIl8SUvg7bNgODg9JgfFYLAu1yDF6q2gQDeeEqvDHqsG"
    ];
    group = "deploy";
    extraGroups = [ "docker" ];
  };
}

