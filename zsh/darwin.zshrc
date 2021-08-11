# Virtualenvwrapper
# export WORKON_HOME=~/Envs
# export VIRTUALENVWRAPPER_PYTHON=/usr/local/opt/python@3.9/libexec/bin/python
# export VIRTUALENVWRAPPER_SH="/usr/local/bin/virtualenvwrapper.sh"
# export ASDF_WUT="$HOME/.asdf/asdf.sh"

# if [[ -a $VIRTUALENVWRAPPER_SH ]]; then
#   source $VIRTUALENVWRAPPER_SH
# fi

# if [[ -a $ASDF_WUT ]]; then
#   source $ASDF_WUT
# fi

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Sublime Text
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Home stuff
# export PATH="$HOME/.rbenv/bin:$HOME/bin:$PATH"

# Golang
# export PATH="/usr/local/opt/go/libexec/bin:$PATH"
# export GOPATH=$HOME/Code/go

# export PATH="~/.pyenv/shims:$PATH"
# eval "$(pyenv init -)"

# if which pyenv-virtualenv-init > /dev/null; then
#   eval "$(pyenv virtualenv-init -)";
# fi

# if which rbenv > /dev/null; then
#   eval "$(rbenv init -)";
# fi

function tmlogs() {
  log show --predicate 'subsystem == "com.apple.TimeMachine"' --info --last 6h
}


