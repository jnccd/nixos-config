{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.music-player.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables MusicPlayer gui app service";
  };

  config = lib.mkIf config.dobikoConf.notes.enabled {
    systemd.services = lib.custom.mkGuiAppService rec {
      username = globalArgs.mainUser.name;
      repoName = "music-player-avalonia-port";
      repoUrl = "https://github.com/jnccd/${repoName}";
    };
  };
}
