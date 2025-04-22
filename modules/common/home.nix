{ config, pkgs, homeStateVersion, mainUsername, ... }:
{
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    inherit mainUsername;
    homeDirectory = "/home/${mainUsername}";
    stateVersion = homeStateVersion;
  };

  # --- Programs ---

  programs.bash = {
    enable = true;
    shellAliases = { 
      owo = "echo uwu"; # I owo into the void and the void uwus back
    };
  };

  programs.git = {
    enable = true;
    userName  = "jnccd";
    userEmail = "kobidogao@outlook.com";
  };
}