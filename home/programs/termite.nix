{ config, lib, pkgs, ... }:

{
  programs = {
    termite = {
      enable = true;
      allowBold = true;
      backgroundColor = "rgba(0, 0, 0, 0.7)";
      cursorColor = "#ffffff";
      cursorForegroundColor = "#ffffff";
      foregroundColor = "#ffffff";
      audibleBell = true;
      clickableUrl = true;
      dynamicTitle = true;
      scrollOnOutput = true;
      scrollOnKeystroke = true;
      font = "Monospace 16";
    };
  };
}
