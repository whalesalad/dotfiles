export PATH="/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Home stuff
export PATH="$HOME/.rbenv/bin:$HOME/bin:$PATH"

# Golang
export PATH="/usr/local/opt/go/libexec/bin:$PATH"

export GOPATH=$HOME/Code/go

# virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
