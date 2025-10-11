{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    conky
    lm_sensors
    sysstat
    intel-gpu-tools

  ];

  security.wrappers.intel_gpu_top = {
    source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
    capabilities = "cap_perfmon+ep";
    owner = "root";
    group = "root";
    permissions = "0755";
  };

  environment.etc."xdg/autostart/conky.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Conky
    Exec=conky -c ~/.config/conky/conky.conf
    X-GNOME-Autostart-enabled=true
  '';
}
