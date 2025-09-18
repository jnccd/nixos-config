{ config, lib, pkgs, ... }: {
  options.dobikoConf.dotnet.enabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enables dotnet packages";
  };

  config = lib.mkIf config.dobikoConf.dotnet.enabled {
    environment.variables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "true";
    };
    environment.systemPackages = with pkgs; [
      dotnet-sdk
      dotnet-ef

      # For Neovim
      omnisharp-roslyn
      netcoredbg

    ];
  };
}
