{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  helpers = import "${inputs.self}/lib/helpers.nix" { inherit pkgs lib inputs; };
  importableFiles = helpers.listAllLocalImportables ./.;
  mergedImports = lib.attrsets.mergeAttrsList (
    map (f: import f { inherit lib pkgs inputs; }) importableFiles
  );
in
mergedImports
