{ config, lib, pkgs, globalArgs, ... }: {
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.etc."global-dotfiles/.background-image".source =
    ../../dotfiles/.background-image;
  environment.etc."global-dotfiles/.lockscreen-image".source =
    ../../dotfiles/.lockscreen-image;
  environment.etc."global-dotfiles/.login-image".source =
    ../../dotfiles/.login-image;

  # - sddm -

  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = (lib.lists.foldl (a: b: a + "," + b) ""
        ((builtins.genList (x: "nixbld" + (builtins.toString x)) 33)
          ++ [ globalArgs.defaultSystemUsername ]));
    };
    theme = "sddm-astronaut-theme";
  };
}
