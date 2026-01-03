#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

rsync -av ../dotfiles/ ~/

if [[ -n "$COPY_DOTFILES_SUDOLESS" ]]; then
  exit 0
fi

# Propagate terminal settings to all users
while IFS=: read -r user _ uid _ _ home shell; do
  if [ "$home" != "/var/empty" ] && [ -d "$home" ]; then
    echo "$home"
    sudo rsync -av "../dotfiles/.config/nushell/" "$home/.config/nushell/"
    sudo rsync -av "../dotfiles/.config/nvim/" "$home/.config/nvim/"
  fi
done < /etc/passwd