{ config, lib, pkgs, ... }:

with lib;
with import <nixpkgs> { };

{
  services = {
    polybar = (if (config.networking.hostName == "thilo-pc") then {
      enable = false;
      script = ''
        polybar main &
      '';
      config = {
        "bar/main" = {
          monitor = "\${env:MONITOR:DisplayPort-0}";
          width = "100%";
          font-0 = "Roboto:size=11:weight=bold;2";
          height = "3%";
          radius = 0;
          modules-left = "i3";
          modules-center = "date";
          modules-right = "pulseaudio cpu memory volume";
          module-margin-left = 1;
          module-margin-right = 2;
          background = "#000000";
          foreground = "#DD8500";
          tray-position = "right";
          line-color = "#DD8500";
          line-size = 16;
        };
        "bar/ext" = {
          monitor = "\${env:MONITOR:HDMI-A-0}";
          width = "100%";
          font-0 = "Roboto:size=11:weight=bold;2";
          height = "3%";
          radius = 0;
          modules-left = "i3";
          modules-center = "date";
          modules-right = "network ";
          module-margin-left = 1;
          module-margin-right = 2;
          background = "#000000";
          foreground = "#DD8500";

          line-color = "#DD8500";
          line-size = 16;
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%d.%m.%y";
          time = "%H:%M";
          label = "%time% | %date%";
        };
        "module/battery" = {
          type = "internal/battery";
          full-at = 99;
          battery = "BAT0";
          adapter = "AC";
          poll-interval = 5;
        };
        "module/backlight" = {
          type = "internal/backlight";
          card = "amdgpu_bl0";
        };
        "module/i3" = {
          type = "internal/i3";
          pin-workspaces = true;
          strip-wsnumbers = true;
          index-sort = true;
          enable-click = false;
          enable-scroll = false;
          wrapping-scroll = false;
          reverse-scroll = false;
          fuzzy-match = true;
        };
        "module/network" = {
          type = "internal/network";
          interface = "wlp1s0";
          interval = "3.0";
          format-connected = "<label-connected>";
          label-connected = " %essid%";
        };
        "module/cpu" = {
          type = "internal/cpu";
          label = "CPU: %percentage:2%%";
        };
        "module/memory" = {
          type = "internal/memory";
          label = "MEM: %percentage_used%%";
        };
        "module/volume" = {
          type = "internal/alsa";
          label-volume = "VOL: %percentage%";
          label-muted = "MUTED";
          click-left = "pactl set-sink-mute 0 toggle";
          click-right = "pavucontrol &";
        };
      };
    } else {
      enable = true;
      script = ''
        polybar main &
        polybar ext &
      '';
      config = {
        "bar/main" = {
          monitor = "\${env:MONITOR:eDP}";
          width = "100%";
          font-0 = "Roboto:size=12:weight=bold;2";
          height = "3%";
          radius = 0;
          modules-center = "date";
          modules-right = "backlight battery";
          module-margin-left = 3;
          module-margin-right = 3;
          background = "#aa000000";
          foreground = "#DD8500";
          tray-position = "right";

          line-color = "#aaDD8500";
          line-size = 16;
        };
        "bar/ext" = {
          monitor = "\${env:MONITOR:HDMI-A-0}";
          width = "100%";
          font-0 = "Roboto:size=11:weight=bold;2";
          height = "3%";
          radius = 0;
          modules-center = "date";
          modules-right = "backlight battery";
          module-margin-left = 1;
          module-margin-right = 2;
          background = "#000000";
          foreground = "#DD8500";

          line-color = "#DD8500";
          line-size = 16;
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%d.%m.%y";
          time = "%H:%M";
          label = "%time% | %date%";
        };
        "module/battery" = {
          type = "internal/battery";
          full-at = 99;
          battery = "BAT0";
          adapter = "AC";
          poll-interval = 5;
        };
        "module/backlight" = { type = "internal/xbacklight"; };
        "module/i3" = {
          type = "internal/i3";
          pin-workspaces = true;
          strip-wsnumbers = true;
          index-sort = true;
          enable-click = false;
          enable-scroll = false;
          wrapping-scroll = false;
          reverse-scroll = false;
          fuzzy-match = true;
        };
      };
    });
  };
}
