ZSH_THEME="agnoster"
COMPLETION_WAITING_DOTS="true"

UNAME=`uname | tr '[:upper:]' '[:lower:]'`
HOSTNAME=`hostname`

# load env
function lenv() {
  export $(cat .env | xargs)
}

# Function to SSH and attach to tmux session
lu() {
    if [ $# -eq 0 ]; then
        echo "Usage: ssht <namespace>"
        echo "Available sessions:"
        ssh lucifer tmux ls
        return 1
    fi
    ssh lucifer -t "tmux a -t $1"
}

# Alias to list remote tmux sessions
alias luls='ssh lucifer tmux ls'

source "${0:a:h}/${UNAME}.zshrc"

if [[ -f "${0:a:h}/hosts/${HOSTNAME}.zshrc" ]]; then
  source "${0:a:h}/hosts/${HOSTNAME}.zshrc"
fi
