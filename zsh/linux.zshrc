export PATH="/home/michael/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# pbpaste/pbcopy tomfoolery
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
