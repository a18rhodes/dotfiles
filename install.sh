#!/bin/bash

ln -sf ~/dotfiles/.bashrc ~/.bashrc

git config --global include.path "~/dotfiles/.gitconfig"

source ~/.bashrc
echo "Dotfiles and Git config installed!"
