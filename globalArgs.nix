rec {
  stateVersion = "25.05";
  homeStateVersion = stateVersion;

  mainUsername = "dobiko";
  githubUsername = "jnccd";
  email = "kobidogao@outlook.com";

  defaultSystemUsername = "runner";

  nixosConfigPath = "/home/${mainUsername}/git/nixos-config";
}
