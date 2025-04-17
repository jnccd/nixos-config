# !Flakeless behaviour! sudo nixos-rebuild switch
{ config, pkgs, stateVersion, username, ... }: 
{
  # Memory leak if I use vars :(
  networking.hostName = "lt-coffeelake";

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos.nix
    ../../modules/gui/nixos

    # For testing
    ../../modules/miniserver/nixos.nix
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
