{ pkgs, config, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
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
}
