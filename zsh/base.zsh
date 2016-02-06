export PATH="$HOME/.rbenv/bin:/Users/michael/bin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/heroku/bin:$PATH"

# virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

function set-database-url(){
  export DATABASE_URL=$(heroku config:get DATABASE_URL --app $1)
  echo $DATABASE_URL
}

function set-database-url-ssl(){
  export DATABASE_URL="$(set-database-url $1)?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory"
  echo $DATABASE_URL
}

function files-changed(){
  git --no-pager diff --name-only master..`git rev-parse --abbrev-ref HEAD` | grep "$1" | tr "\\n" " "
}

function logs(){
  heroku logs --app "$1"-farmlogs-api-"$2" --tail
}

alias e='emacsclient -t'
alias ec='emacsclient -c'

eval "$(rbenv init -)"

#eval "$(docker-machine env default)"
