{ config, lib, pkgs, ... }: {
  options.dobikoConf.conky.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Shows hardware monitoring info in a compact widget";
  };

  config = lib.mkIf config.dobikoConf.conky.enabled {
    environment.systemPackages = with pkgs; [
      conky
      lm_sensors
      sysstat
      intel-gpu-tools
      bc
      jq

    ];

    security.wrappers.intel_gpu_top = {
      source = "${pkgs.intel-gpu-tools}/bin/intel_gpu_top";
      capabilities = "cap_perfmon+ep";
      owner = "root";
      group = "root";
      permissions = "0755";
    };
  };
}
