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
      Name = homeUser.gitUsername;
      Email = homeUser.email;
    };
  };
}
