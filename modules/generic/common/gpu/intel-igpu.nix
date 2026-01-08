{ config, lib, pkgs, ... }: {
  options.dobikoConf.intel_iGPU.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables intel VAAPI stuff";
  };

  config = lib.mkIf config.dobikoConf.intel_iGPU.enabled {
    hardware.enableAllFirmware = true;
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-ocl
        intel-vaapi-driver
        libva-vdpau-driver
        intel-compute-runtime-legacy1

        intel-media-driver # This is a second driver for dire times
      ];
    };
    environment.sessionVariables = { LIBVA_DRIVER_NAME = "i965"; };
    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver =
        pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    # intel_gpu_top setup
    environment.systemPackages = with pkgs; [ intel-gpu-tools ];
    security.wrappers.intel_gpu_top = {
      source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
      capabilities = "cap_perfmon+ep";
      owner = "root";
      group = "root";
      permissions = "0755";
    };
  };
}
