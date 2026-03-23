{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.fcitx5.layout = lib.mkOption {
    type = lib.types.str;
    default = "us(altgr-intl)";
    description = ''
      Keyboard layout used in fcitx5
      Example: de, en, us, us(altgr-intl)'';
  };
  options.dobikoConf.fcitx5.im = lib.mkOption {
    type = lib.types.str;
    default = "keyboard-us-altgr-intl";
    description = ''
      Keyboard input method used in fcitx5
      Example: keyboard-de, keyboard-en, keyboard-us, keyboard-us-altgr-intl
    '';
  };

  config = {
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
            "Name" =
              if config.dobikoConf.fcitx5.im == "keyboard-us-altgr-intl" then
                "keyboard-de"
              else
                "keyboard-us-altgr-intl";
            "Layout" = if config.dobikoConf.fcitx5.im == "us(altgr-intl)" then
              "de"
            else
              "us(altgr-intl)";
          };
          "Groups/0/Items/2".Name = "pinyin";
          "Groups/0/Items/3".Name = "mozc";
        };
      };
    };
  };
}
