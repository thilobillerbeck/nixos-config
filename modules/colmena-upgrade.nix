{ config, lib, pkgs, ... }:

with lib;

let cfg = config.system.colmenaAutoUpgrade;

in {
  options = {
    system.colmenaAutoUpgrade = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to periodically upgrade NixOS to the latest
          version. If enabled, a systemd timer will run
          `nixos-rebuild switch --upgrade` once a
          day.
        '';
      };

      nixPath = mkOption {
        type = types.str;
        example = "unstable=channel:nixos-unstable";
        default = "unstable=channel:nixos-unstable";
        description = lib.mdDoc ''
          Which nix path to apply
        '';
      };

      gitRepoUrl = mkOption {
        type = types.str;
        default = "https://github.com/thilobillerbeck/nixos-config";
        example = "";
        description = lib.mdDoc ''
          Repository URL for nixos config
        '';
      };

      configPath = mkOption {
        type = types.str;
        default = "/root/nixos-config";
        example = "/root/nixos-config";
        description = lib.mdDoc ''
          Repository URL for nixos config
        '';
      };

      dates = mkOption {
        type = types.str;
        default = "04:40";
        example = "daily";
        description = lib.mdDoc ''
          How often or when upgrade occurs. For most desktop and server systems
          a sufficient upgrade frequency is once a day.

          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };

      allowReboot = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc ''
          Reboot the system into the new generation instead of a switch
          if the new generation uses a different kernel, kernel modules
          or initrd than the booted system.
          See {option}`rebootWindow` for configuring the times at which a reboot is allowed.
        '';
      };

      randomizedDelaySec = mkOption {
        default = "0";
        type = types.str;
        example = "45min";
        description = lib.mdDoc ''
          Add a randomized delay before each automatic upgrade.
          The delay will be chosen between zero and this value.
          This value must be a time span in the format specified by
          {manpage}`systemd.time(7)`
        '';
      };

      rebootWindow = mkOption {
        description = lib.mdDoc ''
          Define a lower and upper time value (in HH:MM format) which
          constitute a time window during which reboots are allowed after an upgrade.
          This option only has an effect when {option}`allowReboot` is enabled.
          The default value of `null` means that reboots are allowed at any time.
        '';
        default = null;
        example = {
          lower = "01:00";
          upper = "05:00";
        };
        type = with types;
          nullOr (submodule {
            options = {
              lower = mkOption {
                description = lib.mdDoc "Lower limit of the reboot window";
                type = types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
                example = "01:00";
              };

              upper = mkOption {
                description = lib.mdDoc "Upper limit of the reboot window";
                type = types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
                example = "05:00";
              };
            };
          });
      };

      persistent = mkOption {
        default = true;
        type = types.bool;
        example = false;
        description = lib.mdDoc ''
          Takes a boolean argument. If true, the time when the service
          unit was last triggered is stored on disk. When the timer is
          activated, the service unit is triggered immediately if it
          would have been triggered at least once during the time when
          the timer was inactive. Such triggering is nonetheless
          subject to the delay imposed by RandomizedDelaySec=. This is
          useful to catch up on missed runs of the service when the
          system was powered down.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.nixos-colmena-upgrade = {
      description = "NixOS Colmena Upgrade";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";

      environment = config.nix.envVars // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root";
      } // config.networking.proxy.envVars;

      path = with pkgs; [ git colmena nix ];

      script = let
        colmenaBin = "${pkgs.colmena}/bin/colmena";
        date = "${pkgs.coreutils}/bin/date";
        readlink = "${pkgs.coreutils}/bin/readlink";
        shutdown = "${config.systemd.package}/bin/shutdown";
      in if cfg.allowReboot then ''
        if [ -d "${cfg.configPath}" ]; then
          cd ${cfg.configPath}
          ${pkgs.git}/bin/git pull
        else
          ${pkgs.git}/bin/git clone ${cfg.gitRepoUrl} ${cfg.configPath}
        fi

        cd ${cfg.configPath}

        NIX_PATH=${cfg.nixPath} ${colmenaBin} apply-local --verbose

        booted="$(${readlink} /run/booted-system/{initrd,kernel,kernel-modules})"
        built="$(${readlink} /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"

        ${optionalString (cfg.rebootWindow != null) ''
          current_time="$(${date} +%H:%M)"

          lower="${cfg.rebootWindow.lower}"
          upper="${cfg.rebootWindow.upper}"

          if [[ "''${lower}" < "''${upper}" ]]; then
            if [[ "''${current_time}" > "''${lower}" ]] && \
               [[ "''${current_time}" < "''${upper}" ]]; then
              do_reboot="true"
            else
              do_reboot="false"
            fi
          else
            # lower > upper, so we are crossing midnight (e.g. lower=23h, upper=6h)
            # we want to reboot if cur > 23h or cur < 6h
            if [[ "''${current_time}" < "''${upper}" ]] || \
               [[ "''${current_time}" > "''${lower}" ]]; then
              do_reboot="true"
            else
              do_reboot="false"
            fi
          fi
        ''}

        if [ "''${booted}" = "''${built}" ]; then
          ${nixos-rebuild} ${cfg.operation} ${toString cfg.flags}
        ${optionalString (cfg.rebootWindow != null) ''
          elif [ "''${do_reboot}" != true ]; then
            echo "Outside of configured reboot window, skipping."
        ''}
        else
          ${shutdown} -r +1
        fi
      '' else ''
        if [ -d "${cfg.configPath}" ]; then
          cd ${cfg.configPath}
          ${pkgs.git}/bin/git pull
        else
          ${pkgs.git}/bin/git clone ${cfg.gitRepoUrl} ${cfg.configPath}
        fi

        cd ${cfg.configPath}

        NIX_PATH=${cfg.nixPath} ${colmenaBin} apply-local --verbose
      '';

      startAt = cfg.dates;

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.timers.nixos-upgrade = {
      timerConfig = {
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = cfg.persistent;
      };
    };
  };
}
