{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    conky
    lm_sensors

  ];

  environment.etc."xdg/autostart/conky.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Conky
    Exec=conky -c ~/.config/conky/conky.conf
    X-GNOME-Autostart-enabled=true
  '';
}
