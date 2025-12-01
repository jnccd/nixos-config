{ config, lib, pkgs, globalArgs, ... }: {
  hardware.system76.kernel-modules.enable = true;

  services.system76-scheduler = {
    enable = true;
    assignments = {
      nix-builds = {
        nice = 15;
        class = "batch";
        ioClass = "idle";
        matchers = [ "nix-daemon" ];
      };
    };
  };
}
