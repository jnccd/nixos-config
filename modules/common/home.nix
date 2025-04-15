{ pkgs, homeStateVersion, username, ... }:
{
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = homeStateVersion;
  };

  # --- Programs ---

  programs.bash = {
    enable = true;
    shellAliases = { 
      rebuild = "sudo nixos-rebuild switch";
    };
  };

  programs.git = {
    enable = true;
    userName  = "jnccd";
    userEmail = "kobidogao@outlook.com";
  };
}