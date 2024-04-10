{ config, pkgs, ... }:

{
  imports = [
    ./../modules/deploymentUser.nix
  ];

  users.deploymentUsers.deploy = {
    deploymentPath = "/var/deploy";
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIl8SUvg7bNgODg9JgfFYLAu1yDF6q2gQDeeEqvDHqsG"
    ];
  };
}

