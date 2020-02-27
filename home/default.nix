{ config, lib, pkgs, ... }:

with lib;
with import <nixpkgs> { };

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "f5c9303cedd67a57121f0cbe69b585fb74ba82d9";
    ref = "release-19.09";
  };
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  imports = [ "${home-manager}/nixos" ];

  home-manager.users.thilo = { ... }: {
    services.network-manager-applet.enable = if (config.networking.hostName == "thilo-pc") then false else true;
    services.blueman-applet.enable =  if (config.networking.hostName == "thilo-pc") then false else true;
    services.pasystray.enable = if (config.networking.hostName == "thilo-pc") then false else true;

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

      lorri.enable = true;
    };

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

      git = {
        enable = true;
        userName = "Thilo Billerbeck";
        userEmail = "thilo.billerbeck@officerent.de";
      };

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
      bat = { enable = true; };
      chromium = {
        enable = true;
        extensions = [
          "hdokiejnpimakedhajhdlcegeplioahd" # LastPass
          "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock
        ];
      };
      fzf = { enable = true; };
      direnv = { enable = true; };
      go = {
        enable = true;
        package = unstable.go;
      };
      htop = { enable = true; };
      jq = { enable = true; };
      mpv = { enable = true; };
      obs-studio = { enable = true; };
      tmux = { enable = true; };
      neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [ nerdtree fugitive vim-nix coc-nvim ];
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
      };
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.numix-gtk-theme;
        name = "Numix";
      };
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus";
      };
      gtk3 = { extraConfig = {
        gtk-application-prefer-dark-theme = true;
#        gtk-modules = "appmenu-gtk-module";
        };
      };
    };
  };
}
