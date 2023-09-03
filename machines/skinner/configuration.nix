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

}