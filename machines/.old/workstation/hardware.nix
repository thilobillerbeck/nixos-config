# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];

  boot = {
    initrd = {
      availableKernelModules =
        [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules =
      [ "kvm-amd" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
    extraModulePackages = [ ];
    kernelParams = [ "amd_iommu=on" "iommu=pt" "processor.max_cstate=5" "idle=nomwait" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    cleanTmpDir = true;
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/06954d52-f66b-4273-ba0d-9836e40560b1";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/89D9-19C7";
      fsType = "vfat";
    }; 

  swapDevices = [ ];

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    steam-hardware.enable = true;
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    };
  };

  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  nix.maxJobs = lib.mkDefault 16;
}