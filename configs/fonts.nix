{ config, pkgs, ... }: {
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;

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
