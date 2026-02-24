{ pkgs, lib, ... }:
{
  userNameToPostgresRoleName = username:
    lib.replaceStrings [ "-" "." ] [ "_" "_" ] username;

  listAllLocalImportables = path:
    builtins.map (f: (path + "/${f}")) (builtins.attrNames
      (lib.attrsets.filterAttrs (path: _type:
        (_type == "directory") # include directories
        || ((path != "default.nix") # ignore default.nix
          && (lib.strings.hasSuffix ".nix" path) # include .nix files
        )) (builtins.readDir path)));
} // (import ./service.nix { inherit pkgs lib; })
