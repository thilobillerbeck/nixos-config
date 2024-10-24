let
  thilo1 =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4DBDw+gSP6Wg/uf0unSxqSVV/y6OCcu7TLFdXYCmw7 thilo@avocadoom-laptop";
  thilo2 =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX0RK+JzRkMsO/88NIyBXzQPr8/XkPX3IeClFmj9G8u thilo@thilo-pc";
  users = [ thilo1 thilo2 ];

  bart =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPyYSHb6TkwIBi/5PAtVZa5Qx5subC+xOyQJO/fmk0G";
  burns =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC74r4ElKQlbRtS9HnrV/wc5bcyaYKNaS/fFgffxnXfb";
  krusty =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqawo+unXia1wuw3mWGAyoiiw7mP+JXUtuJNaP14Hbh";
  lisa =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJwf1+7C62c+D/6junwIkCGEskoXICETel6E3CNYQcD";
  skinner =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJfmDTHJxyvAAKcEAflDkjBMRyz4f6xaswhCPyQh/YC";
  systems = [ bart burns krusty lisa skinner ];
in {
  # bart
  "woodpeckerGiteClientId.age".publicKeys = users ++ [ bart ];
  "woodpeckerGiteClientSecret.age".publicKeys = users ++ [ bart ];
  "giteaMailerPassword.age".publicKeys = users ++ [ bart ];
  "giteaDatabasePassword.age".publicKeys = users ++ [ bart ];
  "woodpeckerEnv.age".publicKeys = users ++ systems;

  # burns
  "burnsBackupEnv.age".publicKeys = users ++ systems;
  "vaultwardenConfigEnv.age".publicKeys = users ++ [ burns ];

  # shared
  "woodpecker-secret.age".publicKeys = users ++ [ bart lisa ];
  "resticBackupPassword.age".publicKeys = users ++ systems;

  # docker
  "watchtower-env.age".publicKeys = users ++ systems;

  # webhook
  "webhooksecret.age".publicKeys = users ++ systems;

  # coolify
  "coolify-env-file.age".publicKeys = users ++ [ skinner ];
}
