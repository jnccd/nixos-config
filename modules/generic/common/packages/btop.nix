{
  config,
  lib,
  pkgs,
  hostArgs,
  ...
}:
{
  config = lib.mkIf hostArgs.enableNonEssentialCommonPkgs.enabled {
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
