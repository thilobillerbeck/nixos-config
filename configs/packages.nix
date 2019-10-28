{ pkgs, ... }:

let unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
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
}
