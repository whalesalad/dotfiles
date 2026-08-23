# dotfiles

### Setup

1. Ensure that `zsh` is installed. Don't worry about setting it as your shell, ohmyzsh will do that.
2. Install ohmyzsh: https://ohmyz.sh/#install

Machine setup runbooks:

- [Voxtype push-to-talk dictation](docs/voxtype-push-to-talk-runbook.md)

### Neovim

The Neovim config is intentionally small and project-scoped. Link it into the
standard config location:

```sh
mkdir -p ~/.config
ln -s ~/code/dotfiles/nvim ~/.config/nvim
```

See [`nvim/README.md`](nvim/README.md) for the usage guide and
[`nvim/DEVELOPING.md`](nvim/DEVELOPING.md) for maintenance and extension.

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
