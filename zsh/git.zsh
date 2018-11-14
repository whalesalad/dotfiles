function gfc() {
  git \
    --no-pager diff \
    --name-only master..`git rev-parse --abbrev-ref HEAD`
}

function gb() {
  git for-each-ref \
    --sort=-committerdate \
    refs/heads/ \
    --format='%(align:left,20)%(color:green)%(committerdate:relative)%(color:reset)%(end) %(align:left,50)%(color:yellow)%(refname:short)%(color:reset)%(end) %(color:red)%(objectname:short)%(color:reset) %(contents:subject) (%(authorname))'
}
