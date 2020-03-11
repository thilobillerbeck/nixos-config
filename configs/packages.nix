{ config, pkgs, ... }:

let 
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  services.udev.packages = with pkgs; [ qlcplus ola ];
  environment.systemPackages = with pkgs; [
    # BASH TOOLS
    gitAndTools.hub
    gitAndTools.tig
    up
    termite
    ranger
    nox
    vagrant
    kubectl
    gnupg
    curl
    unzip
    zip
    imagemagick
    youtube-dl
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
    nixfmt

    # LANGUAGES & COMPILERS
    ruby
    lessc
    sbt
    php
    phpPackages.composer
    yosys
    nextpnr
    icestorm
    verilog
    trellis
    pandoc
    scala
    erlang
    python3
    unstable.go
    openjdk
    unstable.nodejs
    qt5.full
    qtcreator

    # GUI TOOLS
    thunderbird
    mumble
    pavucontrol
    texmaker
    postman
    arandr
    nitrogen
    texlive.combined.scheme-full
    wineWowPackages.stable
    inkscape
    discord
    spotify

    # GAMING
    lutris
    minetest
    minecraft
    steam
    
    # JETBRAINS
    unstable.jetbrains.goland
    unstable.jetbrains.idea-ultimate
    unstable.jetbrains.phpstorm
    unstable.jetbrains.pycharm-professional
    unstable.jetbrains.webstorm
    unstable.jetbrains.ruby-mine
  ];
}
