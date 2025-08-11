{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = lib.mkIf config.dobikoConf.bedtime.enabled {
    services.cron = let
      delayMin = "3";
      bedtimeTime = "0 23";
    in {
      enable = true;
      systemCronJobs = [
        "${bedtimeTime} * * *      root    shutdown +${delayMin}"
        ''
          ${bedtimeTime} * * *      ${globalArgs.mainUsername}    kdialog --passivepopup "Bedtime in ${delayMin} minutes." 10''
      ];
    };
  };
}
