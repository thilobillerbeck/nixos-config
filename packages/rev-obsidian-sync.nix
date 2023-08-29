{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "rev-obsidian-sync";
  version = "0.0.1.1";

  src = fetchFromGitHub {
    owner = "acheong08";
    repo = "rev-obsidian-sync";
    rev = "v${version}";
    hash = "sha256-8mo3NfKie+CcvzeJcMla3eDOS+ogoXTs9+PovgArhpI=";
  };

  vendorHash = "sha256-uMBWFEHA4FURKpOBaCCd1bPqbRcqNS0rXoCiW8lT2EY=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Reverse engineering of the native Obsidian sync and publish server";
    homepage = "https://github.com/acheong08/rev-obsidian-sync";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
  };
}