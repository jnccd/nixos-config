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

  config = lib.mkIf config.dobikoConf.notes.enabled {
    # KDE autostart via the XDG autostart spec; the generated launcher clones
    # and refreshes the repo and runs it through its `#desktop` dev shell.
    # `artifacts` is the binary start_desktop_app.sh runs on its "unchanged"
    # branch - the launcher uses it to tell a successful build from a failed
    # one, so the app script itself stays a plain if/else.
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "notes";
      repoName = "notes";
      repoUrl = "https://github.com/jnccd/notes";
      artifacts = [ "NotesAvalonia.Desktop/bin/Release/net10.0/NotesAvalonia.Desktop.dll" ];
      # Run it in a screen session so the build output and runtime errors stay
      # inspectable: `screen -r gui-notes-<user>-<session>` to attach, or read
      # ~/.local/state/gui-autostart/notes.log (and .launcher.log for the git
      # side). Useful while these apps are still being debugged.
      screenWrap = true;
    };
  };
}
