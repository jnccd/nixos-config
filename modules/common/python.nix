{ config, lib, pkgs, globalArgs, ... }: {
  environment.systemPackages = with pkgs;
    [
      (python3.withPackages (ps:
        with ps; [
          requests
          numpy

        ]))
    ];
}
