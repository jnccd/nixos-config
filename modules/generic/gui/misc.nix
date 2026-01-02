{ inputs, config, lib, pkgs, globalArgs, ... }: {
  hardware.bluetooth.enable = true;

  # - images -

  environment.etc."global-dotfiles/.background-image.jpeg".source =
    "${inputs.self}/assets/.background-image.jpeg";
  environment.etc."global-dotfiles/.lockscreen-image.jpeg".source =
    "${inputs.self}/assets/.lockscreen-image.jpeg";
  environment.etc."global-dotfiles/.login-image.jpeg".source =
    "${inputs.self}/assets/.login-image.jpeg";
}
