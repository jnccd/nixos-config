{ config, pkgs, globalArgs, ... }: {
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      signageos.signageos-vscode-sops

      streetsidesoftware.code-spell-checker

      ms-dotnettools.csdevkit
      ms-python.python

      ms-vscode-remote.remote-ssh
    ];

    # profiles.default.userSettings = {
    #   "git.autofetch" = true;
    #   "latex-workshop.view.pdf.viewer" = "tab";
    #   "git.confirmSync" = false;
    #   "git.enableSmartCommit" = true;
    #   "[latex]" = { "editor.defaultFormatter" = "mathematic.vscode-latex"; };
    #   "terminal.integrated.persistentSessionScrollback" = 1000;
    #   "terminal.integrated.scrollback" = 100000;
    #   "latex.formatter.columnLimit" = 600;
    #   "latex-workshop.message.latexlog.exclude" =
    #     [ ".*ChkTeX does not handle lines over.*" ];
    #   "cSpell.customDictionaries" = { };
    #   "cSpell.maxNumberOfProblems" = 500;
    #   "cSpell.maxDuplicateProblems" = 25;
    #   "cSpell.numSuggestions" = 24;
    #   "cSpell.dictionaryDefinitions" = [ ];
    #   "cSpell.language" = "en;de";
    #   "editor.formatOnSave" = true;
    #   "workbench.iconTheme" = "material-icon-theme";
    #   "[typescriptreact]" = {
    #     "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #   };
    #   "workbench.colorTheme" = "Default Dark+";
    #   "diffEditor.ignoreTrimWhitespace" = false;
    #   "csharp.experimental.debug.hotReload" = true;
    #   "csharp.debug.hotReloadVerbosity" = "detailed";
    #   "nix.enableLanguageServer" = true;
    #   "nix.serverPath" = "nil";
    #   "nix.serverSettings" = {
    #     "nil" = {
    #       "diagnostics" = { "ignored" = [ "unused_binding" ]; };
    #       "formatting" = { "command" = [ "nixfmt" ]; };
    #       "nix" = { "flake" = { "autoEvalInputs" = true; }; };
    #     };
    #   };
    #   "nix.formatterPath" = "nixfmt";
    # };
  };
}
