#!/bin/bash

ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.github ~/.github

git config --global include.path "~/dotfiles/.gitconfig"

source ~/.bashrc
echo "Dotfiles and Git config installed!"
