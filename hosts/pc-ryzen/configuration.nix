{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic
  ];

  # --- Custom Module Settings ---

  dobikoConf.nvidia.enabled = true;
  dobikoConf.gaming.enabled = true;

  # --- Misc ---

  services.xserver.xkb = {
    layout = "us,de";
    variant = "altgr-intl,";
    options = "grp:win_space_toggle";
  };

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = false;
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";

    grub.default = "2";
  };
}
