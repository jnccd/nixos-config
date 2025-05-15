{ config, pkgs, globalArgs, ... }:
{
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    username = globalArgs.mainUsername;
    homeDirectory = "/home/${globalArgs.mainUsername}";
    stateVersion = globalArgs.homeStateVersion;
  };

  # --- Programs ---

  programs.bash = {
    enable = true;
    shellAliases = { 
      owo = "echo uwu"; # I owo into the void and the void uwus back
      nix-rb = "sudo nixos-rebuild switch --flake .?submodules=1 && home-manager switch -b backup --flake .?submodules=1";
      nix-gc = "nix-collect-garbage -d";
    };
  };

  programs.git = {
    enable = true;
    userName  = globalArgs.githubUsername;
    userEmail = globalArgs.email;
  };
}