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

  config = lib.mkIf config.dobikoConf.music-player.enabled {
    environment.systemPackages = with pkgs; [
      pulseaudio

    ];

    systemd.services = lib.custom.mkGuiAppService rec {
      username = globalArgs.mainUser.name;
      repoName = "music-player-avalonia-port";
      repoUrl = "https://github.com/jnccd/${repoName}";
      defineEnvVarsScript = ''
        export LD_LIBRARY_PATH="${pkgs.pulseaudio}/lib/:$LD_LIBRARY_PATH"
        export PULSE_SERVER=unix:/run/user/$(id -u ${username})/pulse/native
      '';
    };
  };
}
