#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

cp -r ../dotfiles/.config/ ~
cp -r ../dotfiles/.local/ ~
cp ../dotfiles/.background-image ~
cp ../dotfiles/.nanorc ~