{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    htop
    manpages
    tmux
    tree
    wget
    vim
    neovim
    zsh
    git
    curl
    unzip
  ];
}
