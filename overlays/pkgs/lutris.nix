{ config, pkgs, ... }:

self: super:

{
  lutris = super.lutris.overrideAttrs (old: rec {
    version = "0.5.4";

    src = pkgs.fetchFromGitHub {
      owner = "lutris";
      repo = "lutris";
      rev = "v${version}";
      sha256 = "0n6xa3pnwvsvfipinrkbaxwjfbw2cjpc9igv97nffcmpydmn5xv";
    };
  });
}
