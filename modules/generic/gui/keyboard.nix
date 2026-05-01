{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.fcitx5.layout = lib.mkOption {
    type = lib.types.str;
    default = "us";
    description = ''
      Keyboard layout used in fcitx5
      Example: de, us, us-intl, us(altgr-intl)'';
  };
  options.dobikoConf.fcitx5.im = lib.mkOption {
    type = lib.types.str;
    default = "keyboard-us-altgr-intl";
    description = ''
      Keyboard input method used in fcitx5
      Example: keyboard-de, keyboard-us, keyboard-us-intl, keyboard-us-altgr-intl
    '';
  };

  config = {
    environment.sessionVariables = { SKIP_FCITX_USER_PATH = ""; };
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        ignoreUserConfig = false;
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
            "Name" =
              if config.dobikoConf.fcitx5.im == "keyboard-us-altgr-intl" then
                "keyboard-de"
              else
                "keyboard-us-altgr-intl";
            "Layout" =
              if config.dobikoConf.fcitx5.layout == "us" then "de" else "us";
          };
          "Groups/0/Items/2".Name = "pinyin";
          "Groups/0/Items/3".Name = "mozc";
        };
      };
    };
  };
}
