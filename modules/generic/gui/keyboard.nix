{ inputs, config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.fcitx5.layout = lib.mkOption {
    type = lib.types.str;
    default = "en";
    description = "Keyboard layout used in fcitx5";
  };

  config = {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        ignoreUserConfig = true;
        addons = with pkgs; [
          kdePackages.fcitx5-qt
          kdePackages.fcitx5-chinese-addons
          fcitx5-mozc # Japanese
        ];
        settings = {
          inputMethod = {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = config.dobikoConf.fcitx5.layout;
              DefaultIM = "keyboard-${config.dobikoConf.fcitx5.layout}";
            };
            "Groups/0/Items/0".Name =
              "keyboard-${config.dobikoConf.fcitx5.layout}";
            "Groups/0/Items/1".Name =
              if (config.dobikoConf.fcitx5.layout == "en") then
                "keyboard-de"
              else
                "keyboard-en";
            "Groups/0/Items/2".Name = "pinyin";
            "Groups/0/Items/3".Name = "mozc";
          };
        };
      };
    };
  };
}
