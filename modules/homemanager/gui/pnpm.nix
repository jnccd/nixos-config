{ pkgs, ... }:
if false then
  { }
else
  {
    home.packages = with pkgs; [
      pnpm
    ];

    home.sessionPath = [
      "$HOME/.local/share/pnpm/bin"
    ];

    home.sessionVariables = {
      PATH = "$PATH:$HOME/.local/share/pnpm/bin";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };
  }
