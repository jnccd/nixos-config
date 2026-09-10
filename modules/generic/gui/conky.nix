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

    # Ensure Conky runs at most once. This is not a long-running app - it just
    # culls duplicates - so it is a oneshot autostart entry, which also makes it
    # run per-user inside their session.
    environment.etc = lib.custom.mkGuiAppAutostart {
      appName = "conky-culler";
      repoName = "conky-culler";
      repoUrl = "unused";
      launcherScript = ''
        cull_conky() {
          PIDS=$(pgrep -x conky || true)
          COUNT=$(echo "$PIDS" | wc -w)

          if [ "$COUNT" -gt 1 ]; then
              echo "Found $COUNT Conky processes. Keeping one, killing the rest..."
              FIRST_PID=$(echo "$PIDS" | head -n 1)
              echo "$PIDS" | grep -v "^$FIRST_PID$" | xargs -r kill
          else
              echo "One or no Conky instances running."
          fi
        }

        cull_conky
        sleep 1
        cull_conky
        sleep 3
        cull_conky
        sleep 15
        cull_conky
      '';
    };
  };
}
