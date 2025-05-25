{ config, pkgs, globalArgs, ... }: {
  home.packages = with pkgs; [ dotnet-sdk dotnet-ef ]; # For C# dev
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;

    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      signageos.signageos-vscode-sops

      pkief.material-icon-theme
      esbenp.prettier-vscode

      streetsidesoftware.code-spell-checker

      ms-dotnettools.csdevkit
      ms-python.python

      ms-vscode-remote.remote-ssh
    ];
  };
}
