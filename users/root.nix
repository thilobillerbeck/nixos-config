{ config, lib, pkgs, ... }: { users.users.root = { shell = pkgs.zsh; }; }
