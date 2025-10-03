{ config, lib, pkgs, ... }: {
  # Print
  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
    drivers = with pkgs; [
      cups-filters
      gutenprint
      gutenprintBin
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.ipp-usb.enable = true;
  # Sometimes it is necessary to use: sudo cupsenable <printer_name>; sudo cupsaccept <printer_name>
  # Often it works best to register the printer in http://localhost:631 manually

  # Scan
  hardware.sane.enable = true;
  hardware.sane.extraBackends = with pkgs; [ brscan4 sane-airscan ];
  hardware.sane.brscan4.enable = true;
  services.udev.packages = [ pkgs.sane-airscan ];
  environment.systemPackages = with pkgs; [
    brscan4
    sane-backends
    kdePackages.skanlite
  ];
}
