#!/bin/bash

# Symlink bashrc to the home directory
ln -sf ~/dotfiles/.bashrc ~/.bashrc

# Source it immediately so it takes effect
source ~/.bashrc

echo "Dotfiles installed!"
