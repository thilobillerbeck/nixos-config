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
        "helm"
      ];
    };
    shellInit = ''
      export TERM=xterm-256color
      npm set prefix ~/.npm-global
      PATH=$PATH:$HOME/.npm-global/bin:$HOME/.config/composer/vendor/bin
      eval "$(direnv hook zsh)"
    '';
  };
}
