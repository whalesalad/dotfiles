# dotfiles

### Setup

1. Ensure that `zsh` is installed. Don't worry about setting it as your shell, ohmyzsh will do that.
2. Install ohmyzsh: https://ohmyz.sh/#install

Clone this locally and ensure the `~/.zshrc` contains something like this:

```
# Path to your oh-my-zsh installation.
ZSH="/home/michael/.oh-my-zsh"
ZSH_CUSTOM=$HOME/code/dotfiles/zsh

source $ZSH/oh-my-zsh.sh
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
