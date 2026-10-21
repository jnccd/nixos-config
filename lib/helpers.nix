{ pkgs, lib, ... }:
{
  listAllLocalImportables =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );

  userNameToPostgresRoleName = username: lib.replaceStrings [ "-" "." ] [ "_" "_" ] username;

  # Can be removed, can unwrap lib.mkDefault variables
  unwrapOverrideSet =
    val: if builtins.isAttrs val && val ? _type && val._type == "override" then val.content else val;
}
