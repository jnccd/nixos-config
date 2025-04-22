{ config, pkgs, stateVersion, mainUsername, ... }:
{
  system.stateVersion = stateVersion;
  
  # --- Nix ---

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  users.users.${mainUsername} = {
    isNormalUser = true;
    description = mainUsername;
    extraGroups = [ "networkmanager" "input" "wheel" ];
    packages = [];
  };

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    home-manager

    git
    curl
    wget

    htop
    neofetch

    nushell
    screen
    sops

    vim
  ];

  # nix-collect-garbage -d
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

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
}
