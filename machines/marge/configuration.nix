{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
    ./../../users/deploy.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.05";

  networking = {
    hostName = "marge";
    nameservers = [ "8.8.8.8" ];
    defaultGateway = "172.31.1.1";
    firewall = { allowedTCPPorts = [ 22 25 80 110 143 443 465 587 993 995 4190 ]; };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="116.203.63.1"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:1c1c:761c::1"; prefixLength=64; }
          /* { address="fe80::9400:2ff:fe96:594d"; prefixLength=64; } */
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="96:00:02:96:59:4d", NAME="eth0"
  '';

  virtualisation = {
    docker = { enable = true; };
  };
}
