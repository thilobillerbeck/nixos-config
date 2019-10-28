{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  nixpkgs.config.allowUnfree = true;

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "en_US.UTF-8";
  };

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    ddate
    file
    htop
    manpages
    tmux
    tree
    wget
    vim
    (neovim.override {
      configure = {
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [ nerdtree fugitive vim-nix coc-nvim ];
          opt = [ ];
        };
      };
    })
    wine
    zsh
    chromium
    vscode
    git
    gnumake
    gcc
    linuxHeaders
    spotify
    numix-gtk-theme
    numix-icon-theme-circle
    adapta-gtk-theme
    adapta-kde-theme
    gnupg
    curl
    unzip
    imagemagick
    youtube-dl
    unstable.go
    openjdk
    unstable.nodejs
    watchman
    vagrant
    kubectl
    steam
    steam-run
    python3
    discord
    nox
    inkscape
    scala
    erlang
    lutris
    ntfs3g
    mpv
    yosys
    nextpnr
    icestorm
    verilog
    trellis
    bat

    unstable.jetbrains.goland
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.phpstorm
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.webstorm
  ];

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "fishy";
      plugins = [
        "colorize"
        "colored-man-pages"
        "command-not-found"
        "cp"
        "extract"
        "git"
        "gitignore"
        "sbt"
      ];
    };
    shellAliases = {
      cccda-weechat =
        ''ssh -t avocadoom@shells.darmstadt.ccc.de "tmux attach -t weechat"'';
      w17-door-summer = "ssh summer@door.w17.io";
      w17-door-open = "ssh open@door.w17.io";
      w17-door-close = "ssh close@door.w17.io";
      wine = "wine64";
    };
    shellInit = ''
      npm set prefix ~/.npm-global
      PATH=$PATH:$HOME/.npm-global/bin:$HOME/.config/composer/vendor/bin
      export LC_ALL=${config.i18n.defaultLocale}
    '';
  };

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    fontconfig.ultimate.preset = "osx";

    fonts = with pkgs; [
      terminus_font
      source-code-pro
      powerline-fonts
      google-fonts
      noto-fonts
      fira
      fira-mono
      fira-code
    ];
  };
}

