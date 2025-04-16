# My NixOS Flake

![image](https://github.com/user-attachments/assets/d01d1363-8a59-4cd7-8c2c-b340982a4fc8)

I feel like while writing this config I found a million different ways to shoot myself into the foot. People will tell you "But NixOS is reliable and stable". Dont believe their lies. I wrote flakes that livelock with memory leaks. I wrote flakes that literally destroy the entire system. You might think "But NixOS has profiles, you can just roll bock". No, my flakes broke all profiles at once. Look me deep in the eyes and you might find my last shred of sanity.

But flakes are definitely reproducible which is neat.

## Installation

1. Use the nixos iso installer to get the basic system
2. `sudo nixos-generate-config`
3. Edit the initial config to get git and add the desired hostname in networking.hostname, also add `nix.settings.experimental-features = ["nix-command" "flakes"];` so you can use flakes later
4. `sudo nixos-rebuild switch`
5. Reboot
6. Generate a new ssh key and register it to your github/gitlab
7. Clone the nixos-config repo via ssh
8. In the flake.nix, add the new host in the hosts array
9. In the hosts folder, add a folder for the given hostname and within it the `hardware-configuration.nix` from the initial config
10. Populate the hostname folder with the configuration.nix and home.nix from another host to init
11. `sudo nixos-rebuild switch --install-bootloader --flake .` <- if your computer just fucking dies during this step you fucked up and have to start from the beginning again :)
12. `home-manager switch --flake .`
13. `bash copy-dotfiles/from-repo-to-home.sh`
14. Reboot for good measure
15. Log into vivaldi or your favorite browser, sync settings, (maybe try out [my style](https://github.com/jnccd/vivaldi-style))
16. I dont know how to sync KDE Plasma widgets using nix yet, so install the missing ones (and log out / in to reload the desktop environment)
17. Done, enjoy :)

## Tip

Whenever you change and rebuild a flake, make sure to look at the memory usage of the system. 
You might have created a memory leak thats about to fill up your swapfile :)

[Me when memory leek](https://www.reddit.com/r/196/comments/13z6p1x/hatsune_miku_devouring_her_leek/)
