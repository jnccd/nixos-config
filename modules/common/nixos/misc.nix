{ config, lib, pkgs, globalArgs, ... }: {
  system.stateVersion = globalArgs.stateVersion;

  # --- Clear tmp files ---

  boot.tmp.cleanOnBoot = true;

  # --- Locale ---

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
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
}
