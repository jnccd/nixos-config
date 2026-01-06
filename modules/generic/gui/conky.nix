{ config, lib, pkgs, globalArgs, ... }: {
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

    security.wrappers.intel_gpu_top = {
      source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
      capabilities = "cap_perfmon+ep";
      owner = "root";
      group = "root";
      permissions = "0755";
    };

    systemd.services =
      lib.custom.mkWrappedScreenService { # Ensure Conky runs at most once
        sessionName = "conky-culler";
        username = globalArgs.mainUser.name;
        scriptDirName = "conky-culler";
        wantedBy = [ "graphical.target" ];
        requires = [ "graphical.target" ];
        after = [ "graphical.target" ];
        script = pkgs.writeScript "script" ''
          function cull_conky() {
            PIDS=$(pgrep -x conky)
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
