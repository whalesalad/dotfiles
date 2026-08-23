#!/usr/bin/env zsh

set -eu

TEST_DIR=${0:A:h}
REPO_ROOT=${TEST_DIR:h}
ASSERTIONS=0

fail() {
  print -ru2 -- "not ok - $*"
  exit 1
}

pass() {
  (( ASSERTIONS += 1 ))
  print -r -- "ok $ASSERTIONS - $1"
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
  pass "$message"
}

ZSH_THEME=agnoster
AGNOSTER_CONTEXT_BG=black
HOST=VIPER.mk3.dev

build_prompt() { : }

source "$REPO_ROOT/zsh/prompt.zsh"

if _agnoster_context_text michael ''; then
  fail 'local michael context is hidden'
else
  pass 'local michael context is hidden'
fi

_agnoster_context_text michael '10.0.0.1 12345 22'
assert_equal '%m' "$REPLY" 'SSH michael context contains only the hostname'

_agnoster_context_text root ''
assert_equal '%n@%m' "$REPLY" 'non-michael context contains user and hostname'

_agnoster_host_foreground viper.mk3.dev
viper_color=$REPLY
_agnoster_host_foreground VIPER.quad5.net
assert_equal "$viper_color" "$REPLY" 'hostname color uses the lowercased short hostname'

_agnoster_host_foreground lucifer.quad5.net
lucifer_color=$REPLY
[[ "$lucifer_color" != "$viper_color" ]] || fail 'representative hostnames receive distinct colors'
pass 'representative hostnames receive distinct colors'

approved_palette=(196 197 198 201 202 208 214 220 135 39 45 82)
for color in "$viper_color" "$lucifer_color"; do
  (( ${approved_palette[(Ie)$color]} )) || fail "host color $color belongs to the approved palette"
done
pass 'host colors belong to the approved palette'

saved_path=("${path[@]}")
path=(/path/without/cksum)
rehash
_agnoster_host_foreground viper
assert_equal 208 "$REPLY" 'missing cksum uses the bright orange fallback'
path=("${saved_path[@]}")
rehash

captured_segment=()
prompt_segment() {
  captured_segment=("$@")
}

SSH_CLIENT='10.0.0.1 12345 22'
prompt_context
assert_equal black "$captured_segment[1]" 'context retains the dark Agnoster background'
assert_equal "$AGNOSTER_CONTEXT_HOST_FG" "$captured_segment[2]" 'context uses the host-derived foreground'
assert_equal '%m' "$captured_segment[3]" 'context suppresses michael in the rendered segment'

print -r -- "1..$ASSERTIONS"
