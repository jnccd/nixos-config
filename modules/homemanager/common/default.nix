{ config, pkgs, globalArgs, homeUser, ... }: {
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    username = homeUser.name;
    homeDirectory = "/home/${homeUser.name}";
    stateVersion = globalArgs.homeStateVersion;
  };

  # --- Programs ---

  programs.git = {
    enable = true;
    settings.user = {
      Name = homeUser.gitUsername;
      Email = homeUser.email;
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
