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

    # Start conky, and keep exactly one instance alive.
    #
    # Conky gets started by two things at login: this entry, and KDE's "restore
    # last session", which relaunches it directly and therefore bypasses this
    # script entirely - so the shared helper's per-session flock cannot see the
    # restored copy. That is why the previous version of this file started
    # nothing and only culled duplicates, which worked but left conky depending
    # on KDE to bring it back. This does both:
    #
    #   - if a conky is already running (restored), adopt it and start nothing,
    #     so this entry never adds a second one;
    #   - otherwise start it in the foreground, so the launcher holds any lock it
    #     took for as long as conky lives;
    #   - either way, cull duplicates over the next few seconds, because KDE's
    #     copy can appear slightly after this entry runs.
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "conky";
      launcherScript = ''
        # Store paths rather than PATH: at autostart time PATH is the session's
        # and need not carry procps.
        pgrep=${pkgs.procps}/bin/pgrep
        head=${pkgs.coreutils}/bin/head
        sleep=${pkgs.coreutils}/bin/sleep

        keep_one_conky() {
          local pids first
          # -u "$UID": only ever consider this session's own conkys. pgrep lists
          # every user's, and trying to kill another account's would just fail.
          pids="$($pgrep -u "$UID" -x conky 2>/dev/null || true)"
          [ -n "$pids" ] || return 0
          first="$(printf '%s\n' "$pids" | $head -n 1)"
          for pid in $pids; do
            [ "$pid" = "$first" ] || kill "$pid" 2>/dev/null || true
          done
        }

        # A late duplicate should not hold up startup, so settle them on a timer.
        (
          for delay in 1 3 10; do
            $sleep "$delay"
            keep_one_conky
          done
        ) &

        if $pgrep -u "$UID" -x conky >/dev/null 2>&1; then
          echo "gui-autostart conky: an instance is already running, not starting one"
          # Wait for the culls, so the launcher does not release its lock before
          # duplicates have been dealt with.
          wait
          exit 0
        fi

        exec conky -c "$HOME/.config/conky/conky.conf"
      '';
    };
  };
}
