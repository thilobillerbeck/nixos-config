{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "obi-sync";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "acheong08";
    repo = "obi-sync";
    rev = "v${version}";
    hash = "sha256-l4yErWQjPZHbCk66GhlScY97rbYy9XMKr/9tGc82UE8=";
  };

  vendorHash = "sha256-A/WQ9GCGiA9rncGI+zTy/iqmaXsOa4TIU7XS9r6wMnQ=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Reverse engineering of the native Obsidian sync and publish server";
    homepage = "https://github.com/acheong08/obi-sync";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
  };
}
