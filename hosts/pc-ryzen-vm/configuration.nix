# !Flakeless behaviour! sudo nixos-rebuild switch
{ config, lib, pkgs, globalArgs, ... }: 
{
  # Memory leak if I use vars :(
  networking.hostName = "pc-ryzen-vm";

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos.nix
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
