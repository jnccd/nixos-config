{ config, lib, pkgs, ... }: {
  options.dobikoConf.nvidia.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "For people with the green GPUs";
  };

  config = lib.mkIf config.dobikoConf.nvidia.enabled {
    hardware.graphics = { enable = true; };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia
      cudaPackages.cuda_nvml_dev
      cudaPackages.cudatoolkit
    ];
  };
}
