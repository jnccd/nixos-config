{ config, lib, pkgs, ... }: {
  options.dobikoConf.gaming-mouse.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Gaming Mice config support";
  };

  config = lib.mkIf config.dobikoConf.gaming-mouse.enabled {
    services.ratbagd.enable = true;
    environment.systemPackages = with pkgs; [ piper ];
  };
}
