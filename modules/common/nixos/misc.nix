{ config, lib, pkgs, globalArgs, ... }: {
  system.stateVersion = globalArgs.stateVersion;

  # --- Sops-Nix ---

  sops.defaultSopsFile = ../../../secrets/main.yaml;
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

  # --- Global Aliases ---

  environment.shellAliases = {
    owo = "echo uwu"; # I owo into the void and the void uwus back

    nix-rb =
      "sudo nixos-rebuild switch --flake /home/${globalArgs.mainUsername}/git/nixos-config?submodules=1 && home-manager switch -b backup --flake /home/${globalArgs.mainUsername}/git/nixos-config?submodules=1 && bash copy-dotfiles/from-repo-to-home.sh";
    nix-gc = "nix-collect-garbage -d";

    git-pull = "git pull && git submodule update --recursive --remote";
    "cd.." = "cd ..";
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
  services.openssh.enable = true;

  # --- ACME ---

  security.acme = {
    acceptTerms = true;
    defaults.email = globalArgs.email;
  };
}
