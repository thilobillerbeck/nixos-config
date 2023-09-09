{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "obi-sync";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "acheong08";
    repo = "obi-sync";
    rev = "v${version}";
    hash = "sha256-rVzWJ7kbak8H8YR0VV8Xb2jEqFHO37h/bWzuLt7iMTM=";
  };

  vendorHash = "sha256-+3rs9p+4I+kNoZFKyEuVTLBAU7+b4eYDyNkvZrVyC6U=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Reverse engineering of the native Obsidian sync and publish server";
    homepage = "https://github.com/acheong08/obi-sync";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
  };
}
