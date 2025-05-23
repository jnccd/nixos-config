{ config, pkgs, globalArgs, ... }: {
  programs.git = {
    enable = true;
    userName = globalArgs.githubUsername;
    userEmail = globalArgs.email;
  };

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
    bash.enable = true;
  };
}
