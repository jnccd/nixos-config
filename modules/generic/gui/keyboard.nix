{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.fcitx5.layout = lib.mkOption {
    type = lib.types.str;
    default = "de";
    description = "Keyboard layout used in fcitx5";
  };
  options.dobikoConf.fcitx5.im = lib.mkOption {
    type = lib.types.str;
    default = "keyboard-de";
    description = "Keyboard input method used in fcitx5";
  };

  config = {
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
        ignoreUserConfig = true;
        addons = with pkgs; [
          fcitx5-configtool
          fcitx5-chinese-addons
          fcitx5-mozc
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
            "Name" = if config.dobikoConf.fcitx5.im == "keyboard-us" then
              "keyboard-de"
            else
              "keyboard-us";
            "Layout" =
              if config.dobikoConf.fcitx5.im == "en" then "de" else "en";
          };
          "Groups/0/Items/2" = {
            "Name" = "pinyin";
            "Layout" = "";
          };
          "Groups/0/Items/3" = {
            "Name" = "mozc";
            "Layout" = "";
          };
          "GroupOrder" = { "0" = "Default"; };
        };
      };
    };
    environment.etc."xdg/fcitx5/conf/keyboard.conf".text =
      "EnableHintByDefault=False";
    environment.sessionVariables = {
      XMODIFIERS = "@im=fcitx";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };
  };
}
