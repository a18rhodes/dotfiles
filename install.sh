#!/bin/bash

ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.vimrc ~/.vimrc

PROJECT_ROOT=$(find /workspaces -maxdepth 1 -mindepth 1 -type d | head -n 1)
if [ -n "$PROJECT_ROOT" ]; then
    echo "Found project root at: $PROJECT_ROOT"
    mkdir -p "$PROJECT_ROOT/.github"
    ln -sf ~/dotfiles/copilot-instructions.md "$PROJECT_ROOT/.github/copilot-instructions.md"
    echo "Copilot instructions injected."
    GITIGNORE="$PROJECT_ROOT/.gitignore"
    if [ -f "$GITIGNORE" ]; then
        if ! grep -q ".github/copilot-instructions.md" "$GITIGNORE"; then
            echo "" >> "$GITIGNORE"
            echo "# Private Copilot Instructions (Injected by Dotfiles)" >> "$GITIGNORE"
            echo ".github/copilot-instructions.md" >> "$GITIGNORE"
            echo "Added instructions to .gitignore."
        fi
    fi
else
    echo "No project workspace found. Skipping Copilot injection."
fi

git config --global include.path "~/dotfiles/.gitconfig"

source ~/.bashrc
