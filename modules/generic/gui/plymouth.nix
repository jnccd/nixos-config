{ inputs, config, lib, pkgs, globalArgs, ... }: {
  boot = {
    plymouth = {
      enable = true;
      theme = "motion";
      themePackages = with pkgs;
        [
          (adi1090x-plymouth-themes.override {
            selected_themes = [ "motion" ];
          })
        ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
