{ config, pkgs, ... }:

{
  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups =
      [ "audio" "wheel" "docker" "libvirtd" "networkmanager" "qemu-libvirtd" ];
  };
}

