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
  };
}
