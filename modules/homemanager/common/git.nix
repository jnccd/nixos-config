{
  config,
  pkgs,
  globalArgs,
  homeUser,
  ...
}:
{
  programs.git = {
    enable = true;
    settings.user = {
      Name = homeUser.gitUsername or null;
      Email = homeUser.email or null;
    };
  };
}
