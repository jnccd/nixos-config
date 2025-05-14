# !Flakeless behaviour! sudo nixos-rebuild switch
{ config, lib, pkgs, globalArgs, hostname, ... }: 
{
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos.nix
    ../../modules/gui/nixos
  ];

  # --- Flags ---

  #mySteam.enabled = true;

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
