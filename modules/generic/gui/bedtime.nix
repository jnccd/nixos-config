{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = lib.mkIf config.dobikoConf.bedtime.enabled {
    environment.systemPackages = with pkgs; [ kdePackages.kdialog ];

    services.cron = let
      bedTimeToJobs = { bedTimeMin, bedTimeHour, delayMin ? 3 }:
        [
          "${builtins.toString bedTimeMin} ${
            builtins.toString bedTimeHour
          } * * *      root    shutdown +${
            builtins.toString delayMin
          } >> /tmp/cron.log"
        ] ++ (map (delayPassed:
          ''
            ${builtins.toString (bedTimeMin + delayPassed)} ${
              builtins.toString bedTimeHour
            } * * *      ${globalArgs.mainUser.name}    ${
              lib.custom.bashGetGuiVarsForUser globalArgs.mainUser.name
            } kdialog --sorry "Bedtime in ${
              builtins.toString (delayMin - delayPassed)
            } minutes." "You really need to go to bed :(" >> /tmp/cron.log 2>&1'')
          (builtins.genList (i: i) delayMin));
    in {
      enable = true;
      systemCronJobs = (bedTimeToJobs {
        bedTimeHour = 22;
        bedTimeMin = 30;
      }) ++ (bedTimeToJobs {
        bedTimeHour = 23;
        bedTimeMin = 0;
      }) ++ (bedTimeToJobs {
        bedTimeHour = 23;
        bedTimeMin = 30;
      }) ++ (bedTimeToJobs {
        bedTimeHour = 0;
        bedTimeMin = 0;
      });
    };
  };
}
