{ pkgs, homeUser, ... }: {
  # --- Main User ---

  home = {
    username = homeUser.name;
    homeDirectory = "/home/${homeUser.name}";
    stateVersion = "25.11";
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
