{ config, lib, pkgs, ... }: {
  services.printing.enable = true;
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.brscan4 pkgs.brscan5 pkgs.sane-airscan ];
  hardware.sane.brscan4 = {
    enable = true;
    netDevices = {
      home = {
        model = "MFC-J6520DW";
        ip = "192.168.188.22";
      };
    };
  };
  services.udev.packages = [ pkgs.sane-airscan ];
  #services.ipp-usb.enable = true;

  environment.systemPackages = with pkgs; [
    brscan4
    sane-backends
    kdePackages.skanlite
  ];
}
