{ config, pkgs, ... }:

{
  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck";
    shell = pkgs.zsh;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9TwM1zgEQiU8Cl0OszpU/fba4NpG2rjNSoTvvm/Vcf thilo@thilo-pc"
    ];
    extraGroups =
      [ "audio" "wheel" "docker" "libvirtd" "networkmanager" "qemu-libvirtd" ];
  };
}

