{ config, lib, pkgs, globalArgs, ... }: {
  # --- Programs ---

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      signageos.signageos-vscode-sops

      pkief.material-icon-theme
      esbenp.prettier-vscode

      streetsidesoftware.code-spell-checker

      ms-python.python
      dbaeumer.vscode-eslint

      ms-vscode-remote.remote-ssh
    ]; # [ ms-dotnettools.csdevkit ] have to be installed manually
  };
}
