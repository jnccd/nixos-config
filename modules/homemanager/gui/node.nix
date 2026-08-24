{ pkgs, hostArgs, ... }:
if !hostArgs.enableNonEssentialCommonPkgs then
  { }
else
  {
    home.packages = with pkgs; [
      pnpm
      nodejs_22
    ];

    # Set up bashrc
    programs.bash = {
      enable = true;
      bashrcExtra = ''
        mkdir -p ~/.npm-global
        npm config set prefix '~/.npm-global'
        export PATH=~/.npm-global/bin:$PATH
      '';
    };

    # Those dont seem to work 🤔
    home.sessionPath = [
      "$HOME/.local/share/pnpm/bin"
    ];
    home.sessionVariables = {
      PATH = "$PATH:$HOME/.local/share/pnpm/bin";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };
  }
