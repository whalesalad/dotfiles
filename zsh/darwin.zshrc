# Virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/local/opt/python/libexec/bin/python

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Home stuff
export PATH="$HOME/.rbenv/bin:$HOME/bin:$PATH"

# Python 3
export PATH="/usr/local/opt/python/libexec/bin:$PATH"

# Golang
export PATH="/usr/local/opt/go/libexec/bin:$PATH"

export GOPATH=$HOME/Code/go

# virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

function tmlogs() {
  log show --predicate 'subsystem == "com.apple.TimeMachine"' --info --last 6h
}
