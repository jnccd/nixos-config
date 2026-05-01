{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.ambilight.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables ambilight packages";
  };

  config = lib.mkIf config.dobikoConf.ambilight.enabled {
    environment.systemPackages = with pkgs;
      [
        hyperhdr

      ];

    systemd.services = lib.custom.mkWrappedScreenService rec {
      sessionName = "hyperhdr-starter";
      username = globalArgs.mainUser.name;
      scriptDirName = sessionName;
      wantedBy = [ "graphical.target" ];
      requires = [ "graphical.target" ];
      after = [ "graphical.target" ];
      script = pkgs.writeScript "script" ''
        sleep 6
        export ${lib.custom.bashGetGuiVarsForUser globalArgs.mainUser.name} 
        hyperhdr
      '';
    };
  };
}
