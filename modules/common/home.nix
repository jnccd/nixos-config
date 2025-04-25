{ config, pkgs, globalArgs, ... }:
{
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    inherit (globalArgs) mainUsername;
    homeDirectory = "/home/${globalArgs.mainUsername}";
    stateVersion = globalArgs.homeStateVersion;
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
    userName  = globalArgs.githubUsername;
    userEmail = globalArgs.email;
  };
}