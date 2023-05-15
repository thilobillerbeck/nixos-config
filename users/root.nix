{ config, lib, pkgs, ... }: {
  users.users.root = {
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys =
      config.users.users.thilo.openssh.authorizedKeys.keys ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcjUNTzZ2lZTDFzCrWynnZAu+47IwI/WXmNBRAT9lZZ d"
      ];
  };
}
