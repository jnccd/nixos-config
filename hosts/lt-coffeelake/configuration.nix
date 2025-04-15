# !Flakeless behaviour! sudo nixos-rebuild switch
{ config, pkgs, stateVersion, username, ... }: 
{
  # Memory leak if I use vars :(
  networking.hostName = "lt-coffeelake";

  # --- Imports ---

  imports = [
    ../../modules/common/nixos.nix
    ../../modules/gui/nixos.nix

    ./hardware-configuration.nix
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
