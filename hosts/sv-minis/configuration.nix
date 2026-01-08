{ inputs, config, lib, pkgs, globalArgs, hostname, ... }: {
  networking.hostName = hostname;

  # --- Imports ---

  imports = [
    ./hardware-configuration.nix

    ../../modules/generic/common
    ../../modules/machine/miniserver
  ];

  # --- Hardware ---

  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-ocl
      intel-vaapi-driver
      libva-vdpau-driver
      intel-compute-runtime-legacy1

      intel-media-driver # This is a second driver for dire times
    ];
  };
  environment.systemPackages = with pkgs; [ intel-gpu-tools ];
  environment.sessionVariables = { LIBVA_DRIVER_NAME = "i965"; };
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver =
      pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };

  # --- Bootloader ---

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
