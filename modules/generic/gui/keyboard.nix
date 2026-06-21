{
  inputs,
  config,
  lib,
  pkgs,
  globalArgs,
  ...
}:
let
  defaultLayout = "us-altgr-intl";
  defaultIM = "keyboard-us-altgr-intl";

  secondaryLayout = "de";
  secondaryIM = "keyboard-de";
in
{
  options.dobikoConf.fcitx5.layout = lib.mkOption {
    type = lib.types.str;
    default = defaultLayout;
    description = ''
      Keyboard layout used in fcitx5
      Example: de, us, us-intl, us-altgr-intl, us(altgr-intl)'';
  };
  options.dobikoConf.fcitx5.im = lib.mkOption {
    type = lib.types.str;
    default = defaultIM;
    description = ''
      Keyboard input method used in fcitx5
      Example: keyboard-de, keyboard-us, keyboard-us-intl, keyboard-us-altgr-intl
    '';
  };

  config = {
    environment.sessionVariables = {
      #SKIP_FCITX_USER_PATH = "";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      QT_IM_MODULES = "fcitx";
    };
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        ignoreUserConfig = true;
        waylandFrontend = true;
        addons = with pkgs; [
          kdePackages.fcitx5-qt
          kdePackages.fcitx5-chinese-addons
          fcitx5-mozc # Japanese
        ];
        settings.inputMethod = {
          "Groups/0" = {
            "Name" = "Default";
            "Default Layout" = config.dobikoConf.fcitx5.layout;
            "DefaultIM" = config.dobikoConf.fcitx5.im;
          };
          "Groups/0/Items/0" = {
            "Name" = config.dobikoConf.fcitx5.im;
            "Layout" = config.dobikoConf.fcitx5.layout;
          };
          "Groups/0/Items/1" = {
            "Name" = if config.dobikoConf.fcitx5.im == defaultIM then secondaryIM else defaultIM;
            "Layout" =
              if config.dobikoConf.fcitx5.layout == defaultLayout then secondaryLayout else defaultLayout;
          };
          "Groups/0/Items/2".Name = "pinyin";
          "Groups/0/Items/3".Name = "mozc";
        };
      };
    };
  };
}
