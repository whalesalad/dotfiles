# dotfiles

### Setup

Clone this locally and ensure the `~/.zshrc` contains something like the following:

```
ZSH_CUSTOM=$HOME/Code/dotfiles/zsh

```


### Emacs

I do not miss using Emacs at all.

Prerequesites:

    export CODE_PATH="$(pwd)/emacs"
    mkdir -p ~/.emacs.d/
    cd ~/.emacs.d/
    ln -s $CODE_PATH/init.el
    ln -s $CODE_PATH/Cask

    brew install cask

    cask
