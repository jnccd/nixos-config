{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dobikoConf.intel_iGPU = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enables intel VAAPI stuff";
    };
    driver = lib.mkOption {
      type = lib.types.enum [
        "iHD"
        "i965"
      ];
      default = "iHD";
      description = ''
        VAAPI driver selected through LIBVA_DRIVER_NAME.

        "iHD" (intel-media-driver) is the modern driver and the only one that
        works on Wayland. The legacy "i965" (intel-vaapi-driver) still uses the
        wl_drm protocol, which libwayland/mesa no longer exports, so it fails
        with "failed to resolve wl_drm_interface" and breaks VAAPI (and thus
        video playback) under Wayland.

        Only fall back to "i965" for pre-Gen8 (Broadwell and older) hardware
        that intel-media-driver does not support.
      '';
    };
  };

  config = lib.mkIf config.dobikoConf.intel_iGPU.enabled {
    hardware.enableAllFirmware = true;
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-ocl
        intel-compute-runtime-legacy1

        intel-media-driver # iHD, the driver selected by default
        intel-vaapi-driver # i965, legacy fallback (broken on Wayland)
        libva-vdpau-driver
      ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = config.dobikoConf.intel_iGPU.driver;
    };
    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
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
