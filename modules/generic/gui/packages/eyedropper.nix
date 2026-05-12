{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.eyedropper.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables eyedropper packages";
  };

  config = lib.mkIf config.dobikoConf.eyedropper.enabled {
    environment.systemPackages = with pkgs;
      [
        inputs.instant-eyedropper-r.packages."${system}".default

      ];

    systemd.services = lib.custom.mkWrappedScreenService rec {
      sessionName = "eyedropper-starter";
      username = globalArgs.mainUser.name;
      scriptDirName = sessionName;
      wantedBy = [ "graphical.target" ];
      requires = [ "graphical.target" ];
      after = [ "graphical.target" ];
      script = pkgs.writeScript "script" ''
        sleep 6
        ${lib.custom.bashGetUserEnvVars globalArgs.mainUser.name} 
        ie-r
      '';
    };
  };
}
