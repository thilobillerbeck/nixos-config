{ config, pkgs, lib, fetchFromGitea, ... }:

let
  sources = import ./../../nix/sources.nix;
  unstable = import sources.unstable { config.allowUnfree = true; };
in {
  imports =
    [ ./../../configs/server.nix
    ./hardware.nix ];

  time.timeZone = "Europe/Berlin";
  system.stateVersion = "22.11";

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
}
