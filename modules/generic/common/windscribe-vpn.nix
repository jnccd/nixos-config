{ config, lib, pkgs, globalArgs, ... }: {
  options.dobikoConf.windscribe.enabled = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enables windscribe network interface";
  };

  config = lib.mkIf config.dobikoConf.windscribe.enabled {
    # - Sops-Nix -
    sops.secrets."windscribe/private_key" = {
      owner = globalArgs.mainUser.name;
    };
    sops.secrets."windscribe/preshared_key" = {
      owner = globalArgs.mainUser.name;
    };

    # - Interface -
    networking.wg-quick.interfaces = {
      wg0 = {
        address = [ "100.110.207.220/32" ];
        dns = [ "1.1.1.1" ];
        privateKeyFile = config.sops.secrets."windscribe/private_key".path;

        peers = [{
          publicKey = "dxMoXE/9ztTLm2UK0g6GxO1TLya8vxF7pZpX7LABuAI=";
          presharedKeyFile =
            config.sops.secrets."windscribe/preshared_key".path;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "yyz-292-wg.whiskergalaxy.com:65142";
          persistentKeepalive = 25;
        }];
      };
    };
  };
}
