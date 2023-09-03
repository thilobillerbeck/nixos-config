{ config, pkgs, lib, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable {
    config.allowUnfree = true;
    system = "aarch64-linux";
  };
in
{
  imports = [
    ./hardware.nix
    ./../../configs/server.nix
  ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "23.11";

  networking.firewall.allowedTCPPorts = [ 6443 30779 ];

  services.k3s = {
    enable = true;
    role = "server";
  };

  environment.systemPackages = [ pkgs.k3s pkgs.kubectl pkgs.kubernetes-helm ];

  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
