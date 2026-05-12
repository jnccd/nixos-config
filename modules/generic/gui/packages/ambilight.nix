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

    systemd.services = lib.custom.mkGuiAutostartService {
      sessionName = "eyedropper-starter";
      username = globalArgs.mainUser.name;
      script = pkgs.writeScript "script" ''
        hyperhdr
      '';
    };
  };
}
