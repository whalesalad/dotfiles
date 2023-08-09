ZSH_THEME="agnoster"
COMPLETION_WAITING_DOTS="true"

UNAME=`uname | tr '[:upper:]' '[:lower:]'`
HOSTNAME=`hostname`

# load env
function lenv() {
  export $(cat .env | xargs)
}

source "${0:a:h}/${UNAME}.zshrc"

if [[ -f "${0:a:h}/hosts/${HOSTNAME}.zshrc" ]]; then
  source "${0:a:h}/hosts/${HOSTNAME}.zshrc"
fi