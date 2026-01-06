#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

if [[ -n "$COPY_DOTFILES_SUDOLESS" ]]; then
  rsync -av ../dotfiles/ ~/
else
    # Propagate terminal settings to all users
    while IFS=: read -r user _ uid gid _ home shell; do
    if [ "$home" != "/var/empty" ] && [ "$home" != "/run/dbus" ] && [ "$home" != "/var/lib/davis" ] && [ -d "$home" ]; then
        echo "$home"
        
        if [ "$uid" -ge 1000 ]; then
            # Real users get everything
            sudo rsync -av --chown=$uid:$gid "../dotfiles/" "$home/"
        else
            # System users get terminal settings
            sudo rsync -av --chown=$uid:$gid "../dotfiles/.config/nushell/" "$home/.config/nushell/"
            sudo rsync -av --chown=$uid:$gid "../dotfiles/.config/nvim/" "$home/.config/nvim/"
        fi
    fi
    done < /etc/passwd
fi

