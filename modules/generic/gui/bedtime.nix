{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = lib.mkIf config.dobikoConf.bedtime.enabled {
    environment.systemPackages = with pkgs; [ kdePackages.kdialog ];

    services.cron = let
      delayMin = 3;
      bedTimeMin = 0;
      bedTimeHour = 23;
    in {
      enable = true;
      systemCronJobs = [
        "${builtins.toString bedTimeMin} ${
          builtins.toString bedTimeHour
        } * * *      root    shutdown +${
          builtins.toString delayMin
        } >> /tmp/cron.log"
      ] ++ (map (delayPassed:
        ''
          ${builtins.toString (bedTimeMin + delayPassed)} ${
            builtins.toString bedTimeHour
          } * * *      ${globalArgs.mainUser.name}    WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_DATA_DIRS="/run/current-system/sw/share" kdialog --sorry "Bedtime in ${
            builtins.toString (delayMin - delayPassed)
          } minutes." "You really need to go to bed :(" >> /tmp/cron.log 2>&1'')
        (builtins.genList (i: i) delayMin));
    };
  };
}
