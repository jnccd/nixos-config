{ config, lib, pkgs, ... }: {
  options.dobikoConf.dotnet.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables dotnet packages";
  };

  config = lib.mkIf config.dobikoConf.dotnet.enabled {
    environment.systemPackages = with pkgs; [
      dotnet-sdk
      dotnet-ef

    ];
  };
}
