{ inputs, config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs; [
    kdePackages.sddm-kcm # For sddm/kde screen sync
    kdePackages.qtmultimedia # For theme
    (sddm-astronaut.override {
      embeddedTheme = "purple_leaves";
      themeConfig = {
        FormPosition = "right";
        Background = "/etc/global-dotfiles/.login-image.jpeg";
        DateTextColor = "#b7cef1";
        FormBackgroundColor = "#121b2b";
        BlurMax = "48";
        Blur = "0.4";
      };
    })
  ];

  # Its best to apply the KDE theme manually to SDDM in: System Settings → Startup and Shutdown → Login Screen (SDDM) → Apply Plasma Settings...
  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = (lib.lists.foldl (a: b: a + "," + b) ""
        ((builtins.genList (x: "nixbld" + (builtins.toString x)) 33)
          ++ [ globalArgs.defaultSystemUser.name ]));
      X11.DisplayCommand = "/etc/sddm/scripts/my-xsetup";
    };
    theme = "sddm-astronaut-theme";
  };

  # Only use the first connected display
  environment.etc."sddm/scripts/my-xsetup".text = ''
    #!/bin/sh
    export PATH=${pkgs.xorg.xrandr}/bin:$PATH

    connected_displays=$(xrandr | grep " connected" | cut -d' ' -f1)
    primary=$(echo "$connected_displays" | grep -E '^DP' | head -n 1)
    if [ -z "$primary" ]; then
      primary=$(echo "$connected_displays" | head -n 1)
    fi

    for display in $connected_displays; do
      if [ "$display" = "$primary" ]; then
        xrandr --output "$display" --auto --primary
      else
        xrandr --output "$display" --off
      fi
    done
  '';
}
