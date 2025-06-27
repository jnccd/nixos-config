{ config, lib, pkgs, globalArgs, ... }: {
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.etc."global-dotfiles/.background-image.jpeg".source =
    ../../dotfiles/.background-image.jpeg;
  environment.etc."global-dotfiles/.lockscreen-image.jpeg".source =
    ../../dotfiles/.lockscreen-image.jpeg;
  environment.etc."global-dotfiles/.login-image.jpeg".source =
    ../../dotfiles/.login-image.jpeg;

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
