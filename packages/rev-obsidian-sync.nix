{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "rev-obsidian-sync";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "acheong08";
    repo = "rev-obsidian-sync";
    rev = "v${version}";
    hash = "sha256-sVaq04Pe8aCXMboLX3XrY0qhSBk3PKIEWZtvLsiDHW8=";
  };

  vendorHash = "sha256-A/WQ9GCGiA9rncGI+zTy/iqmaXsOa4TIU7XS9r6wMnQ=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Reverse engineering of the native Obsidian sync and publish server";
    homepage = "https://github.com/acheong08/rev-obsidian-sync/";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
  };
}