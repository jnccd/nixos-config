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
  imports = lib.optional (builtins.pathExists customModulePath) customModulePath;
}
