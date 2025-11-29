{ config, pkgs, globalArgs, ... }: {
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    username = globalArgs.mainUsername;
    homeDirectory = "/home/${globalArgs.mainUsername}";
    stateVersion = globalArgs.homeStateVersion;
  };

  # --- Programs ---

  programs.git = {
    enable = true;
    settings.user = {
      Name = globalArgs.gitUsername;
      Email = globalArgs.email;
    };
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
    bash.enable = true;
  };
}
