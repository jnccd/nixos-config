{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.dobikoConf.nonEssentialCommonPkgs.enabled {
    environment.systemPackages = with pkgs; [ btop ];
    security.wrappers.btop = {
      source = "${pkgs.btop}/bin/btop";
      capabilities = "cap_perfmon+ep";
      owner = "root";
      group = "root";
      permissions = "0755";
    };
  };
}
