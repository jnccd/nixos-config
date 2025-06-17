{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # userMngmnt.additionalUsers = [{
  #   name = "steve";
  #   isAdmin = false;
  #   isSystem = false;
  # }];

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos
    ../../modules/gui/nixos
    ../../modules/dev
  ];

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = false;
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
}
