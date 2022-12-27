{
  meta = {
    nixpkgs = <nixpkgs>;
  };

  defaults = { pkgs, ... }: { };

  bart = { 
    imports = [ ./machines/bart/configuration.nix ]; 
    deployment.targetHost = "bart.thilo-billerbeck.com";
    deployment.targetUser = "thilo";
    deployment.buildOnTarget = true;
  };
}