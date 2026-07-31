# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Sublime Text
#export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
#export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

#eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# time machine logging
function tmlogs() {
  log show --predicate 'subsystem == "com.apple.TimeMachine"' --info --last 6h
}

