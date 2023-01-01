let
  thilo1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4DBDw+gSP6Wg/uf0unSxqSVV/y6OCcu7TLFdXYCmw7 thilo@avocadoom-laptop";
  thilo2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBX0RK+JzRkMsO/88NIyBXzQPr8/XkPX3IeClFmj9G8u thilo@thilo-pc";
  users = [ thilo1 thilo2 ];

  bart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPyYSHb6TkwIBi/5PAtVZa5Qx5subC+xOyQJO/fmk0G";
  burns = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC74r4ElKQlbRtS9HnrV/wc5bcyaYKNaS/fFgffxnXfb";
  krusty = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqawo+unXia1wuw3mWGAyoiiw7mP+JXUtuJNaP14Hbh";
  lisa = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJwf1+7C62c+D/6junwIkCGEskoXICETel6E3CNYQcD";
  systems = [ bart burns krusty lisa ];
in
{
  "woodpecker-secret.age".publicKeys = users ++ [ bart lisa ];
}