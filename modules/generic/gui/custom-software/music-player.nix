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

    # The app's own devShellHook already exports LD_LIBRARY_PATH (pulseaudio)
    # and PULSE_SERVER, so no envScript is needed: the launcher runs inside that
    # dev shell with the desktop session's environment inherited.
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "music-player";
      repoName = "music-player-avalonia-port";
      repoUrl = "https://github.com/jnccd/music-player-avalonia-port";
      # What start_desktop_app.sh executes on its "unchanged" branch; used to
      # verify a build really happened (see lib/service.nix).
      artifacts = [ "MusicPlayerAvaloniaPort/bin/Release/net10.0/MusicPlayerAvaloniaPort.dll" ];
      # Keep the build/runtime output inspectable, same as notes.
      screenWrap = true;
    };
  };
}
