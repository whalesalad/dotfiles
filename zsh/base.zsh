export PATH="/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$HOME/bin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/heroku/bin:/usr/local/share/npm/bin:$PATH"

# virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
