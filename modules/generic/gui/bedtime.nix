{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = let
    cronJobToSystemdTimer = { nameStr, timeStr, user, command }: {
      timer."${nameStr}-${timeStr}-timer" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "${timeStr}";
          Unit = "${nameStr}-${timeStr}.service";
        };
      };
      service."${nameStr}-${timeStr}" = {
        description = "Bedtime Shutdown at ${timeStr}";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${command}";
          User = user;
        };
      };
    };

    bedTimeJobForTime = { bedTimeMin, bedTimeHour, delayMin ? 3 }:
      let
        bedTimeMinStr = builtins.toString bedTimeMin;
        bedTimeHourStr = builtins.toString bedTimeHour;
      in [
        (cronJobToSystemdTimer {
          nameStr = "bedtime-shutdown";
          timeStr = "${bedTimeHourStr}:${bedTimeMinStr}";
          user = "root";
          command = "shutdown +${builtins.toString delayMin}";
        })
      ] ++ (map (delayPassed:
        let warnTimeMinStr = builtins.toString (bedTimeMin + delayPassed);
        in (cronJobToSystemdTimer {
          nameStr = "bedtime-shutdown-warn";
          timeStr = "${bedTimeHourStr}:${warnTimeMinStr}";
          user = "${globalArgs.mainUser.name}";
          command = ''
            bash -c '${lib.custom.bashGetUserVars} && kdialog --sorry "Bedtime in ${
              builtins.toString (delayMin - delayPassed)
            } minutes." "You really need to go to bed :("'
          '';
        })) (builtins.genList (i: i) delayMin));

    bedTimeJobs = (bedTimeJobForTime {
      bedTimeHour = 22;
      bedTimeMin = 30;
    }) ++ (bedTimeJobForTime {
      bedTimeHour = 23;
      bedTimeMin = 0;
    }) ++ (bedTimeJobForTime {
      bedTimeHour = 23;
      bedTimeMin = 30;
    }) ++ (bedTimeJobForTime {
      bedTimeHour = 0;
      bedTimeMin = 0;
    });
  in lib.mkIf config.dobikoConf.bedtime.enabled {
    environment.systemPackages = with pkgs; [ kdePackages.kdialog ];

    systemd.timers =
      lib.foldl (acc: x: acc // x) { } (builtins.map (x: x.timer) bedTimeJobs);
    systemd.services = lib.foldl (acc: x: acc // x) { }
      (builtins.map (x: x.service) bedTimeJobs);
  };
}
