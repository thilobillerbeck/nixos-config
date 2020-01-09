{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  services.udev.packages = with pkgs; [ qlcplus ola ];

  environment.systemPackages = with pkgs; [
    ddate
    file
    htop
    manpages
    tmux
    tree
    wget
    zsh
    wine
    vscode
    gnumake
    gcc
    linuxHeaders
    spotify
    numix-gtk-theme
    numix-icon-theme-circle
    gnupg
    curl
    unzip
    imagemagick
    youtube-dl
    unstable.go
    openjdk
    unstable.nodejs
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
    yosys
    nextpnr
    icestorm
    verilog
    trellis
    pandoc
    texlive.combined.scheme-full
    arandr
    nitrogen
    gitAndTools.hub
    gitAndTools.tig
    up
    thunderbird
    termite
    openiscsi
    ranger
    ruby
    mediainfo
    mumble
    nixfmt
    lessc
    pavucontrol
    sbt
    zip
    texmaker
    qlcplus
    libftdi
    ola
    postman

    jetbrains.goland
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.phpstorm
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.webstorm
    unstable.jetbrains.ruby-mine
  ];
}
