{ config, lib, pkgs, ... }:

with lib;
with import <nixpkgs> { };

{
  programs = {
    rofi = {
      enable = true;
      width = 50;
      lines = 5;
      borderWidth = 0;
      rowHeight = 1;
      padding = 5;
      font = "Roboto 16";
      separator = "solid";
      colors = {
        window = {
          background = "#000000";
          border = "#DD8500";
          separator = "#DD8500";
        };
        rows = {
          normal = {
            background = "#000000";
            foreground = "#DD8500";
            backgroundAlt = "#000000";
            highlight = {
              background = "#DD8500";
              foreground = "#ffffff";
            };
          };
        };
      };
    };
  };
}
