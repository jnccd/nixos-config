{ pkgs, ... }: {
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
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      fill-labs.dependi

      ms-vscode-remote.remote-ssh
    ]; # [ ms-dotnettools.csdevkit ] have to be installed manually
  };
}
