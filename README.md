# dotfiles

### emacs

Prerequesites:

    export CODE_PATH="$(pwd)/emacs"
    mkdir -p ~/.emacs.d/
    cd ~/.emacs.d/
    ln -s $CODE_PATH/init.el
    ln -s $CODE_PATH/Cask

    brew install cask

    cask
