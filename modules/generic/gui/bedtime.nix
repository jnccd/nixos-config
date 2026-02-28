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
          } * * *      ${globalArgs.mainUser.name}    kdialog --passivepopup "Bedtime in ${
            builtins.toString (delayMin - delayPassed)
          } minutes." 10 >> /tmp/cron.log'')
        (builtins.genList (i: i) delayMin));
    };
  };
}
