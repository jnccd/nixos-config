{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ dotnet-sdk dotnet-ef ];

  environment.sessionVariables = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = 1; };
}
