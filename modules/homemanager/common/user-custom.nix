{
  config,
  lib,
  pkgs,
  globalArgs,
  homeUser,
  ...
}:
let
  customModulePath = "/home/${homeUser.name}/home.nix";
in
{
  # This doesnt work yet but it would be kinda cool
  imports = lib.optional (builtins.pathExists customModulePath) (
    builtins.path {
      path = customModulePath;
      filter = _: _: true;
    }
  );
}
