{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/common/nixos
    ../../modules/gui/nixos
    ../../modules/dev
  ];

  # --- Custom Module Settings ---

  gaming.enabled = true;

  # --- NVidia ---

  hardware.graphics = { enable = true; };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # --- Misc ---

  time.hardwareClockInLocalTime = true;
  hardware.enableRedistributableFirmware = true;
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
