{ config, lib, pkgs, globalArgs, ... }: {
  system.stateVersion = globalArgs.stateVersion;

  # --- Tmp files ---

  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;
  boot.tmp.tmpfsSize = "2G";

  # --- Locale ---

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # --- IO ---

  networking.networkmanager.enable = true;
  services.openssh.enable = true;

  # --- ACME ---

  security.acme = {
    acceptTerms = true;
    defaults.email = globalArgs.email;
  };

  # --- Hardware ---

  time.hardwareClockInLocalTime = true;
  hardware.enableRedistributableFirmware = true;
}
