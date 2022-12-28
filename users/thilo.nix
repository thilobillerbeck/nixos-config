{ config, pkgs, ... }:

{
  users.users.thilo = {
    uid = 1000;
    description = "Thilo Billerbeck";
    shell = pkgs.zsh;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9TwM1zgEQiU8Cl0OszpU/fba4NpG2rjNSoTvvm/Vcf thilo@thilo-pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHXL+1Q6MeNJoqaC4IlUXBIhLiRPzyM2Je11rQrXsiD"
      # NEW
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4DBDw+gSP6Wg/uf0unSxqSVV/y6OCcu7TLFdXYCmw7 thilo@avocadoom-laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX0RK+JzRkMsO/88NIyBXzQPr8/XkPX3IeClFmj9G8u thilo@thilo-pc"
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

