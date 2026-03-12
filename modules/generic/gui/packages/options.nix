{ config, lib, pkgs, ... }: {
  options.dobikoConf.nonEssentialGuiPkgs.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables nonEssentialGuiPkgs";
  };
}
