{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.notes.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables notes gui app service";
  };

  options.dobikoConf.music-player.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables MusicPlayer gui app service";
  };

  config = {
    systemd.services =
      (
        if config.dobikoConf.notes.enabled then
          lib.custom.mkGuiAppService rec {
            username = globalArgs.mainUser.name;
            repoName = "notes";
            repoUrl = "https://github.com/jnccd/${repoName}";
          }
        else
          { }
      )
      //
      # (
      #   if config.dobikoConf.music-player.enabled then
      #     lib.custom.mkGuiAppService rec {
      #       username = globalArgs.mainUser.name;
      #       repoName = "music-player-avalonia-port";
      #       repoUrl = "https://github.com/jnccd/${repoName}";
      #     }
      #   else
      #     { }
      # )
      { };
  };
}
