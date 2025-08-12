{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = lib.mkIf config.dobikoConf.bedtime.enabled {
    environment.systemPackages = with pkgs; [ kdePackages.kdialog ];

    services.cron = let
      delayMin = "3";
      bedtimeTime = "0 23";
    in {
      enable = true;
      systemCronJobs = [
        "${bedtimeTime} * * *      root    shutdown +${delayMin} >> /tmp/cron.log"
        ''
          ${bedtimeTime} * * *      ${globalArgs.mainUsername}    kdialog --passivepopup "Bedtime in ${delayMin} minutes." 10 >> /tmp/cron.log''
      ];
    };
  };
}
