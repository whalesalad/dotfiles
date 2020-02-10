function ggfc() {
  git \
    --no-pager diff \
    --name-only master..`git rev-parse --abbrev-ref HEAD`
}

# This is really `heroku deploy`
function gdeploy() {
  git push "${1:-stage}" `git rev-parse --abbrev-ref HEAD`:master
}

function ggb() {
  git for-each-ref \
    --color=always \
    --sort=-committerdate \
    refs/heads/ \
    --format='%(align:left,20)%(color:green)%(committerdate:relative)%(color:reset)%(end) %(align:left,50)%(color:yellow)%(refname:short)%(color:reset)%(end) %(color:red)%(objectname:short)%(color:reset) %(contents:subject) (%(authorname))' \
    | head -n 15
}

function ggraph() {
  git log --graph --full-history --all --color \
          --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"
}

function ggcp() {
  git rev-parse --abbrev-ref HEAD | pbcopy
}
