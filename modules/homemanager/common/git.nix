{
  config,
  lib,
  pkgs,
  globalArgs,
  homeUser,
  ...
}:
{
  programs.git = {
    enable = true;
    settings.user = lib.mkIf (homeUser ? gitUsername) {
      Name = homeUser.gitUsername;
      Email = homeUser.email;
    };
  };
}
