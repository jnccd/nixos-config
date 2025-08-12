{ inputs, config, lib, pkgs, globalArgs, ... }: {
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  # - images -

  environment.etc."global-dotfiles/.background-image.jpeg".source =
    "${inputs.self}/dotfiles/.background-image.jpeg";
  environment.etc."global-dotfiles/.lockscreen-image.jpeg".source =
    "${inputs.self}/dotfiles/.lockscreen-image.jpeg";
  environment.etc."global-dotfiles/.login-image.jpeg".source =
    "${inputs.self}/dotfiles/.login-image.jpeg";
}
