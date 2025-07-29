{ inputs, config, lib, pkgs, globalArgs, ... }: {
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.etc."global-dotfiles/.background-image.jpeg".source =
    "${inputs.self}/dotfiles/.background-image.jpeg";
  environment.etc."global-dotfiles/.lockscreen-image.jpeg".source =
    "${inputs.self}/dotfiles/.lockscreen-image.jpeg";
  environment.etc."global-dotfiles/.login-image.jpeg".source =
    "${inputs.self}/dotfiles/.login-image.jpeg";

  # - sddm -

  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = (lib.lists.foldl (a: b: a + "," + b) ""
        ((builtins.genList (x: "nixbld" + (builtins.toString x)) 33)
          ++ [ globalArgs.defaultSystemUsername ]));
    };
    # Only use the first connected display
    xsetupScript = ''
      #!/bin/sh
      export PATH=${pkgs.xorg.xrandr}/bin:$PATH

      # Get connected displays
      connected_displays=$(xrandr | grep " connected" | cut -d' ' -f1)

      # Choose the first one as primary
      primary=$(echo "$connected_displays" | head -n 1)

      # Turn off all other displays
      for display in $connected_displays; do
        if [ "$display" = "$primary" ]; then
          xrandr --output "$display" --auto --primary
        else
          xrandr --output "$display" --off
        fi
      done
    '';
    theme = "sddm-astronaut-theme";
  };
}
