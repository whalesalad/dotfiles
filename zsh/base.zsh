ZSH_THEME="agnoster"
COMPLETION_WAITING_DOTS="true"

UNAME=`uname | tr '[:upper:]' '[:lower:]'`

# load env
function lenv() {
  export $(cat .env | xargs)
}

source "${0:a:h}/${UNAME}.zshrc"
