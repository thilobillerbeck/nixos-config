{ config, lib, ... }:

with import <nixpkgs> {};

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "b0544c8cded820fc1439c26b4fc7485846430516";
    ref = "master";
  };
in {
  imports = [ "${home-manager}/nixos" ];

  home-manager.users.thilo = { ... }: {
    services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;

    services.polybar = {
      enable = true;
      config = {
        "bar/main" = {
          monitor = "\${env:MONITOR:eDP}";
          width = "100%";
          font-0 = "Roboto:size=11:weight=bold;2";
          height = "3%";
          radius = 0;
          modules-center = "date";
          modules-right = "battery";
          module-margin-left = 1;
          module-margin-right = 2;
          background = "#000000";
          foreground = "#DD8500";

          line-color = "#DD8500";
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
        "module/backlight" = {
          type = "internal/backlight";
          card = "amdgpu_bl0";
        };
      };
      script = ''
        polybar main &
        polybar ext &
      '';
    };

    programs.rofi = {
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

    programs.git = {
      enable = true;
      userName = "Thilo Billerbeck";
      userEmail = "thilo.billerbeck@officerent.de";
    };

    programs.termite = {
      enable = true;
      audibleBell = true;
      clickableUrl = true;
      dynamicTitle = true;
      scrollOnOutput = true;
      scrollOnKeystroke = true;
      font = "Monospace 16";
      backgroundColor = "#000";
      foregroundColor = "#fff";
      hintsForegroundColor = "#DD8500";
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.numix-gtk-theme;
        name = "Numix";
      };
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };
    };
  };
}
