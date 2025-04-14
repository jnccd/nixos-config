# My NixOS Flake

![image](https://github.com/user-attachments/assets/d01d1363-8a59-4cd7-8c2c-b340982a4fc8)

I feel like while writing this config I found a million different ways to shoot myself into the foot. People will tell you "But NixOS is reliable and stable". Dont believe their lies. I wrote flakes that livelock with memory leaks. I wrote flakes that literally destroy the entire system. You might think "But NixOS has profiles, you can just roll bock". No, my flakes broke all profiles at once. Look me deep in the eyes and you might find my last shred of sanity.

But flakes are definitely reproducible which is neat.

## Installation

1. Use the nixos iso installer to get the basic system
2. `sudo nixos-generate-config`
3. Edit the initial config to get git
4. `sudo nixos-rebuild swtich`
5. Generate a new ssh key and register it to your github/gitlab
6. Clone the nixos-config repo via ssh
7. In the hosts folder, add a nixos folder and within it the `hardware-configuration.nix` from the initial config
8. Populate the nixos folder with the configs from another host
9. 
