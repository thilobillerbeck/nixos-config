{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    htop
    man-pages
    tmux
    tree
    wget
    vim
    neovim
    zsh
    git
    curl
    unzip
    ncdu
    (pkgs.writeShellScriptBin "kernel-check-reboot" ''
      currentKernel=$(readlink /run/current-system/kernel)
      bootedKernel=$(readlink /run/booted-system/kernel)
      echo "Current Kernel Path:" $currentKernel
      echo "Booted Kernel Path:" $bootedKernel

      if [[ "$currentKernel" != "$bootedKernel" ]]; then
          echo "Kernel Versions differ. Rebooting...."
          systemctl reboot -i
      else
          echo "Current kernel is booted. Skipping...."
      fi
    '')
  ];
}
