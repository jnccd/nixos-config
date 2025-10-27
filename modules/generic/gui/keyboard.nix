{ inputs, config, lib, pkgs, globalArgs, ... }: {
  services.xserver.xkb = lib.mkDefault {
    layout = "de,us";
    variant = ",altgr-intl";
    options = "grp:win_space_toggle";
  };

  i18n.inputMethod = lib.mkDefault {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      plasma6Support = true;
      addons = with pkgs; [
        fcitx5-configtool
        fcitx5-chinese-addons
        fcitx5-mozc
      ];
      settings.inputMethod = {
        "Groups/0" = {
          "Default Layout" = "en";
          "DefaultIM" = "keyboard-us";
        };
        "Groups/0/Items/0" = {
          "Name" = "keyboard-de";
          "Layout" = "";
        };
        "Groups/0/Items/1" = {
          "Name" = "keyboard-us";
          "Layout" = "";
        };
        "Groups/0/Items/2" = {
          "Name" = "pinyin";
          "Layout" = "de";
        };
        "Groups/0/Items/3" = {
          "Name" = "mozc";
          "Layout" = "de";
        };
        "GroupOrder" = { "0" = "Default"; };
      };
    };
  };
  environment.sessionVariables = { XMODIFIERS = "@im=fcitx"; };
}
