{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ dotnet-sdk dotnet-ef ];

  environment.variables = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1"; };
}
