# save this as shell.nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.colmena
    pkgs.nixfmt
    pkgs.niv
    pkgs.arion
    (pkgs.callPackage "${(import ./nix/sources.nix).agenix}/pkgs/agenix.nix" {})
  ];
  shellHook = ''
    echo $NIX_PATH
  '';
}
