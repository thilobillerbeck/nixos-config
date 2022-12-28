# save this as shell.nix
{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  nativeBuildInputs = [ pkgs.colmena pkgs.nixfmt ];
  shellHook =
  ''
    source .envrc
    echo $NIX_PATH
  '';
}