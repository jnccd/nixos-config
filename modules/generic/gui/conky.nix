{
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
{
  options.dobikoConf.conky.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Shows hardware monitoring info in a compact widget";
  };

  config = lib.mkIf config.dobikoConf.conky.enabled {
    environment.systemPackages = with pkgs; [
      conky
      lm_sensors
      sysstat
      intel-gpu-tools
      bc
      jq

    ];

    # Start conky once per graphical session.
    #
    # This runs through the shared autostart helper so it gets the same
    # per-session flock as the other GUI apps (notes, music-player): the entry
    # lives in the global /etc/xdg/autostart, and KDE's "restore last session"
    # can re-run it, so the lock is what stops a second copy.
    #
    # It replaces a culler that re-ran `pgrep -x conky` a few times after login
    # and killed all but one instance. The lock gives the same single-instance
    # guarantee without the polling or the deliberate sleeps.
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "conky";
      launcherScript = ''
        exec conky -c "$HOME/.config/conky/conky.conf"
      '';
    };
  };
}
