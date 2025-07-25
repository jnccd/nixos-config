{ config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic
  ];

  # --- Custom Module Settings ---

  dobikoConf.gaming.enabled = true;

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
  hardware.bluetooth.enable = true;
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
