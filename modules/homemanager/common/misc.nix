{
  config,
  pkgs,
  globalArgs,
  homeUser,
  ...
}:
{
  # --- Nix ---

  nixpkgs.config.allowUnfree = true;

  # --- Main User ---

  home = {
    username = homeUser.name;
    homeDirectory = "/home/${homeUser.name}";
    stateVersion = globalArgs.homeStateVersion;
  };
}
