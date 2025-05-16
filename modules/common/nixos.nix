{ config, pkgs, globalArgs, ... }: {
  system.stateVersion = globalArgs.stateVersion;

  # --- Nix ---

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  # --- Users ---

  users.defaultUserShell = pkgs.bash;
  users.users.${globalArgs.mainUsername} = {
    isNormalUser = true;
    description = globalArgs.mainUsername;
    extraGroups = [ "networkmanager" "input" "wheel" "nginx" ];
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    home-manager

    git
    curl
    wget
    #skopeo

    htop
    neofetch

    bash
    nushell

    screen
    sops
    age

    neovim
    nixfmt-classic
    nil # LSP for nix lang
  ];

  # nix-collect-garbage -d
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # --- Programs ---

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;

  # --- Sops-Nix ---

  sops.defaultSopsFile = ../../secrets/main.yaml;
  sops.age.keyFile =
    "/home/${globalArgs.mainUsername}/.config/sops/age/keys.txt";
  sops.age.generateKey = true;

  # --- Podman ---

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
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

  # --- ACME ---

  security.acme = {
    acceptTerms = true;
    defaults.email = globalArgs.email;
  };
}
