. $HOME/.asdf/asdf.sh

# Virtualenvwrapper
export WORKON_HOME=~/Envs
export VIRTUALENVWRAPPER_PYTHON=/usr/local/opt/python@3.9/libexec/bin/python
source /usr/local/bin/virtualenvwrapper.sh

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Home stuff
export PATH="$HOME/.rbenv/bin:$HOME/bin:$PATH"

# # Python 3
# export PATH="/usr/local/opt/python/libexec/bin:$PATH"

# pyenv
# if [[ `which pyenv &> /dev/null` ]]; then
#   export PATH="$HOME/.pyenv/bin:$PATH"
#   eval "$(pyenv init -)"
#   eval "$(pyenv virtualenv-init -)"
# fi

# Golang
export PATH="/usr/local/opt/go/libexec/bin:$PATH"
export GOPATH=$HOME/Code/go

eval "$(pyenv init -)";
# eval "$(pyenv virtualenv-init -)"

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

function tmlogs() {
  log show --predicate 'subsystem == "com.apple.TimeMachine"' --info --last 6h
}


