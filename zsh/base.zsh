ZSH_THEME="agnoster"
COMPLETION_WAITING_DOTS="true"

plugins=(git docker rails heroku virtualenv virtualenvwrapper)

UNAME=`uname | tr '[:upper:]' '[:lower:]'`

source "${0:a:h}/${UNAME}.zshrc"
