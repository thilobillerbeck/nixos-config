{ config, lib, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;
      userName = "Thilo Billerbeck";
      userEmail = "thilo.billerbeck@officerent.de";
    };
  };
}
