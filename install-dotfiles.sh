#!/bin/bash
#This file will symlink the dotfiles from this directory to your home dir.
#You can use this to leave your dotfiles elsewhere to sync between machines
read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd $(dirname "$0")
    CWD=`pwd`
    # alias the dotfiles dir so I don't have to remember where it is.
    ln -sf "$CWD" ~/.dotfiles
    #bash files
    ln -sf "$CWD/.aliases" ~/.aliases
    ln -sf "$CWD/.bash_profile" ~/.bash_profile
    ln -sf "$CWD/.bash_prompt" ~/.bash_prompt
    ln -sf "$CWD/.bash_touchbar" ~/.bash_touchbar
    ln -sf "$CWD/.bashrc" ~/.bashrc
    ln -sf "$CWD/.exports" ~/.exports
    ln -sf "$CWD/.secrets" ~/.secrets
    ln -sf "$CWD/.inputrc" ~/.inputrc
    ln -sf "$CWD/.functions" ~/.functions
    #lesspipe (used with LESSOPEN in bash exports)
    rm -rf ~/.dotfiles-bin
    ln -sf "$CWD/.dotfiles-bin" ~/.dotfiles-bin
    #git specific
    ln -sf "$CWD/.gitattributes" ~/.gitattributes
    ln -sf "$CWD/.gitconfig" ~/.gitconfig
    ln -sf "$CWD/.gitignore" ~/.gitignore
    ln -sf "$CWD/.git_template" ~/.git_template
    ln -sf "$CWD/.git-completion.sh" ~/.git-completion.sh
    #vim specific
    ln -sf "$CWD/.gvimrc" ~/.gvimrc
    rm -rf ~/.vim
    ln -sf "$CWD/.vim" ~/.vim
    ln -sf "$CWD/.vimrc" ~/.vimrc
    mkdir -p ~/.vim-tmp
    #ruby specific
    ln -sf "$CWD/.gemrc" ~/.gemrc
    ln -sf "$CWD/.irbrc" ~/.irbrc
    ln -sf "$CWD/.rvmrc" ~/.rvmrc
    #python stuff
    ln -sf "$CWD/.pypirc" ~/.pypirc
    source "$HOME/.bash_profile"
fi
