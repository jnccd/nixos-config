# <img src="https://github.com/user-attachments/assets/d46f6ade-c539-47c6-a7a5-b98c7b4e5559" alt="Diagram" height="40em" style="vertical-align:middle;"> My NixOS Flake

<img src="https://github.com/user-attachments/assets/d01d1363-8a59-4cd7-8c2c-b340982a4fc8" alt="Description" width="450ch" height=auto>

Yeah, I destroyed my system completely multiple times while building this, so I am not sure about the claims of update atomicity.
But flakes are definitely reproducible which is neat.

## What does it look like?

![image](https://github.com/user-attachments/assets/7dbbe417-5878-45d9-be5f-b9e11d94240a)

Like this 👀

Its basically default Plasma 6 Breeze with some light modifications. The idea here was to create a good looking DE that (mostly) doesnt break within the next patch, so I didnt go overboard with any of the modifications.

The background image is from [Alena Aenami](https://www.artstation.com/artwork/n0mwQo). Go check her out, she makes amazing artworks 👀

## Installation

> [!WARNING]
> Since parts of this config are private you`ll have to substitute some imports in the config to make it work. Notably, the dotfiles also reference my main username.

1. Use the nixos iso installer to get the basic system
2. `sudo nixos-generate-config`
3. Edit the initial config to get git and add the desired hostname in networking.hostname
4. `sudo nixos-rebuild switch`
5. Reboot
6. [Generate a new ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and register it to your github/gitlab account
7. Clone the nixos-config repo via ssh into `~/git/nixos-config` (yes the path is important)
8. In the hosts folder, add a folder for the given hostname and within it the `hardware-configuration.nix` from the initial config
9. Populate the hostname folder with `system`, `configuration.nix` and `home.nix` files from another host and adapt them as necessary
10. `sudo nixos-rebuild switch --install-bootloader --flake .`
11. Reboot for good measure
12. `nix-rb`
13. Log into vivaldi or your favorite browser, sync settings, (maybe try out [my style](https://github.com/jnccd/vivaldi-style))
14. Done, enjoy :)

## Tip

Whenever you change and rebuild a flake, make sure to look at the memory usage of the system.

You might have assigned a variable at the wrong place and created an infinite tree thats about to fill up your swapfile :)

[Me when memory leek](https://www.reddit.com/r/196/comments/13z6p1x/hatsune_miku_devouring_her_leek/)

## Inspiration

I mainly learned Nix from [Ampersand's](https://www.youtube.com/watch?v=nLwbNhSxLd4) and [Vimjoyer's](https://www.youtube.com/@vimjoyer) YouTube videos as well as these repos:

https://github.com/Andrey0189/nixos-config-reborn

https://github.com/EmergentMind/nix-config

https://github.com/Baitinq/nixos-config
