{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.bedtime.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Forces you to go to bed";
  };

  config = lib.mkIf config.dobikoConf.bedtime.enabled {
    services.cron = {
      enable = true;
      systemCronJobs =
        [ "0 5 * * *      ${globalArgs.mainUsername}    shutdown -t 180" ];
    };
  };
}
