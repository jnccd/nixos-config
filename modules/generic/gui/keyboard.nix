{ inputs, config, lib, pkgs, globalArgs, ... }: {
  services.xserver.xkb = lib.mkDefault {
    layout = "de,us";
    variant = ",altgr-intl";
    options = "grp:win_space_toggle";
  };
}
