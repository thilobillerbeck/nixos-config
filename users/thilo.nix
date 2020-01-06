{ config, pkgs, ... }:

{
  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck";
    initialPassword = "1234";
    shell = pkgs.zsh;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9TwM1zgEQiU8Cl0OszpU/fba4NpG2rjNSoTvvm/Vcf thilo@thilo-pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHXL+1Q6MeNJoqaC4IlUXBIhLiRPzyM2Je11rQrXsiD"
    ];
    extraGroups = [
      "dialout"
      "adbusers"
      "video"
      "audio"
      "wheel"
      "docker"
      "libvirtd"
      "libvirt"
      "networkmanager"
      "qemu-libvirtd"
    ];
  };
}

