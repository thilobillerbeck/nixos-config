{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    htop
    man-pages
    tmux
    tree
    wget
    vim
    neovim
    zsh
    git
    curl
    unzip
    ncdu
  ];
}
