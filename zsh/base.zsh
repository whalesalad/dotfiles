ZSH_THEME="agnoster"
COMPLETION_WAITING_DOTS="true"

UNAME=`uname | tr '[:upper:]' '[:lower:]'`
HOSTNAME=`hostname`

# load env
function lenv() {
  export $(cat .env | xargs)
}

# Open Lucifer's tmux workspace picker or a named session.
lu() {
    if [ $# -gt 1 ]; then
        echo "Usage: lu [session-name]" >&2
        return 2
    fi

    if [ $# -eq 1 ]; then
        case "$1" in
            ''|*[!A-Za-z0-9_-]*)
                echo "lu: invalid session name: $1" >&2
                return 2
                ;;
        esac
        ssh -t lucifer "\$HOME/code/dotfiles/bin/t $1"
    else
        ssh -t lucifer '$HOME/code/dotfiles/bin/t'
    fi
}

strip_trailing_ws() {
  perl -pe 's/[ \t]+$//'
}

# Alias to list remote tmux sessions
alias luls='ssh lucifer tmux ls'

source "${0:a:h}/${UNAME}.zshrc"

if [[ -f "${0:a:h}/hosts/${HOSTNAME}.zshrc" ]]; then
  source "${0:a:h}/hosts/${HOSTNAME}.zshrc"
fi
