{ config, pkgs, ... }: {
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    # fontconfig.ultimate.preset = "osx";

    fonts = with pkgs; [
      terminus_font
      source-code-pro
      powerline-fonts
      google-fonts
      noto-fonts
      fira
      fira-mono
      fira-code
      jetbrains-mono
    ];
  };
}
