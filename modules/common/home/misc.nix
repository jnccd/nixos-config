{ config, pkgs, globalArgs, ... }: {
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    username = globalArgs.mainUsername;
    homeDirectory = "/home/${globalArgs.mainUsername}";
    stateVersion = globalArgs.homeStateVersion;
  };
}
