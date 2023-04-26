{ config, lib, pkgs, ... }:

{
  programs = {
    neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [ nerdtree fugitive vim-nix coc-nvim ];
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
    };
  };
}
