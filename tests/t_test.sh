#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd "$TEST_DIR/.." && pwd -P)
T_BIN="$REPO_ROOT/bin/t"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/t-test.XXXXXX")
SOCKET="t-test-$$"
ASSERTIONS=0

tmux_test() {
    command tmux -L "$SOCKET" -f "$TEST_TMP/tmux.conf" "$@"
}

cleanup() {
    tmux_test kill-server 2>/dev/null || true
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

fail() {
    printf 'not ok - %s\n' "$*" >&2
    exit 1
}

pass() {
    ASSERTIONS=$((ASSERTIONS + 1))
    printf 'ok %d - %s\n' "$ASSERTIONS" "$1"
}

assert_equal() {
    local expected=$1
    local actual=$2
    local message=$3
    [[ $actual == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
    pass "$message"
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local message=$3
    [[ $haystack == *"$needle"* ]] || fail "$message (missing '$needle')"
    pass "$message"
}

assert_not_contains() {
    local haystack=$1
    local needle=$2
    local message=$3
    [[ $haystack != *"$needle"* ]] || fail "$message (unexpected '$needle')"
    pass "$message"
}

assert_session_absent() {
    local name=$1
    local message=$2
    if tmux_test has-session -t "=$name" 2>/dev/null; then
        fail "$message"
    fi
    pass "$message"
}

assert_command_fails() {
    local message=$1
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$message"
    fi
    pass "$message"
}

session_environment() {
    local session=$1
    local name=$2
    tmux_test show-environment -t "=$session" "$name" 2>/dev/null || true
}

session_path() {
    local session=$1
    tmux_test list-panes -t "=$session" -F '#{pane_current_path}' | head -n 1
}

wait_for_file() {
    local path=$1
    local attempts=0
    while [[ ! -f $path && $attempts -lt 100 ]]; do
        sleep 0.02
        attempts=$((attempts + 1))
    done
    [[ -f $path ]] || fail "timed out waiting for $path"
}

mkdir -p \
    "$TEST_TMP/bin" \
    "$TEST_TMP/alpha" \
    "$TEST_TMP/beta" \
    "$TEST_TMP/bad" \
    "$TEST_TMP/plain"

printf '%s\n' \
    'set -g default-shell /bin/bash' \
    'set -g default-command /bin/bash' \
    > "$TEST_TMP/tmux.conf"

printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case ${1:-} in' \
    '  prefix)' \
    '    [[ ${2:-} == fake ]] || exit 1' \
    '    printf "%s\\n" "$FAKE_PYENV_PREFIX"' \
    '    ;;' \
    '  sh-activate)' \
    '    [[ ${2:-} == fake ]] || exit 1' \
    '    printf "export PYENV_VERSION=\\\"fake\\\";\\n"' \
    '    printf "export PYENV_ACTIVATE_SHELL=1;\\n"' \
    '    printf "export PYENV_VIRTUAL_ENV=\\\"%s\\\";\\n" "$FAKE_PYENV_PREFIX"' \
    '    printf "export VIRTUAL_ENV=\\\"%s\\\";\\n" "$FAKE_PYENV_PREFIX"' \
    '    ;;' \
    '  *) exit 1 ;;' \
    'esac' \
    > "$TEST_TMP/bin/pyenv"
chmod +x "$TEST_TMP/bin/pyenv"

printf '%s\n' \
    "workspace alpha root_dir=\"$TEST_TMP/alpha\" pyenv=\"fake\"" \
    "workspace beta root_dir=\"$TEST_TMP/beta\"" \
    "workspace bad root_dir=\"$TEST_TMP/bad\"" \
    > "$TEST_TMP/workspaces.sh"

printf '%s\n' \
    "PROJECT_TOKEN='hello world'" \
    "SPECIAL_VALUE='dollar \$HOME, quote \"x\", slash \\, semi ;, hash #'" \
    "TILDE_VALUE='~literal'" \
    "MULTILINE_VALUE='first" \
    "second'" \
    > "$TEST_TMP/alpha/.env"
printf '%s\n' 'false' > "$TEST_TMP/bad/.env"

export T_TMUX_SOCKET=$SOCKET
export T_TMUX_CONFIG="$TEST_TMP/tmux.conf"
export T_CONFIG_FILE="$TEST_TMP/workspaces.sh"
export T_NO_ATTACH=1
export FAKE_PYENV_PREFIX="$TEST_TMP/fake-venv"
export PATH="$TEST_TMP/bin:$FAKE_PYENV_PREFIX/bin:$PATH"
export PYENV_VERSION=fake
export PYENV_ACTIVATE_SHELL=1
export PYENV_VIRTUAL_ENV=$FAKE_PYENV_PREFIX
export VIRTUAL_ENV=$FAKE_PYENV_PREFIX
export PROJECT_TOKEN='hello world'

"$T_BIN" alpha

assert_equal \
    'PROJECT_TOKEN=hello world' \
    "$(session_environment alpha PROJECT_TOKEN)" \
    '.env reaches the tmux session environment'
assert_equal \
    'PYENV_VERSION=fake' \
    "$(session_environment alpha PYENV_VERSION)" \
    'configured pyenv version is activated'
assert_equal \
    "VIRTUAL_ENV=$TEST_TMP/fake-venv" \
    "$(session_environment alpha VIRTUAL_ENV)" \
    'configured virtualenv path is activated'
assert_equal \
    'SPECIAL_VALUE=dollar $HOME, quote "x", slash \, semi ;, hash #' \
    "$(session_environment alpha SPECIAL_VALUE)" \
    'environment values survive tmux command quoting'
assert_equal \
    'TILDE_VALUE=~literal' \
    "$(session_environment alpha TILDE_VALUE)" \
    'leading tilde remains literal in environment values'
assert_equal \
    $'MULTILINE_VALUE=first\nsecond' \
    "$(session_environment alpha MULTILINE_VALUE)" \
    'multiline environment values survive tmux command quoting'
assert_equal \
    "$TEST_TMP/alpha" \
    "$(session_path alpha)" \
    'configured session starts in root_dir'

future_environment="$TEST_TMP/future-environment"
tmux_test new-window -d -t '=alpha' -c "$TEST_TMP/alpha" \
    "env > '$future_environment'"
wait_for_file "$future_environment"
assert_contains \
    "$(<"$future_environment")" \
    'PROJECT_TOKEN=hello world' \
    'future windows inherit .env values'
assert_contains \
    "$(<"$future_environment")" \
    "VIRTUAL_ENV=$TEST_TMP/fake-venv" \
    'future windows inherit pyenv activation'

"$T_BIN" beta
assert_equal \
    '-PYENV_VERSION' \
    "$(session_environment beta PYENV_VERSION)" \
    'session without pyenv removes inherited PYENV_VERSION'
assert_equal \
    '-VIRTUAL_ENV' \
    "$(session_environment beta VIRTUAL_ENV)" \
    'session without pyenv removes inherited VIRTUAL_ENV'
assert_not_contains \
    "$(session_environment beta PATH)" \
    "$FAKE_PYENV_PREFIX/bin" \
    'session without pyenv removes inherited virtualenv PATH entry'

assert_command_fails \
    'invalid .env aborts creation' \
    "$T_BIN" bad
assert_session_absent bad 'invalid .env leaves no partial session'

(
    cd "$TEST_TMP/plain"
    "$T_BIN" scratch
)
assert_equal \
    "$TEST_TMP/plain" \
    "$(session_path scratch)" \
    'unknown name creates a plain session at PWD'
assert_equal \
    '-PYENV_VERSION' \
    "$(session_environment scratch PYENV_VERSION)" \
    'plain session is Python-neutral'

assert_command_fails \
    'injection-shaped session name is rejected' \
    "$T_BIN" 'bad;name'
assert_session_absent 'bad;name' 'invalid name never reaches tmux'

printf '%s\n' 'false' > "$TEST_TMP/alpha/.env"
"$T_BIN" alpha
assert_equal \
    'PROJECT_TOKEN=hello world' \
    "$(session_environment alpha PROJECT_TOKEN)" \
    'existing session does not rerun initialization'

printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s" "$(</dev/stdin)" > "$T_FZF_CAPTURE"' \
    'exit 130' \
    > "$TEST_TMP/bin/fzf-cancel"
chmod +x "$TEST_TMP/bin/fzf-cancel"
export T_FZF_BIN="$TEST_TMP/bin/fzf-cancel"
export T_FZF_CAPTURE="$TEST_TMP/fzf-input"
export T_COLUMNS=40
"$T_BIN"

assert_equal \
    $'alpha\nbad\nbeta\nscratch' \
    "$(cut -f 1 "$TEST_TMP/fzf-input")" \
    'picker merges running and configured names alphabetically'
assert_contains \
    "$(cut -f 2 "$TEST_TMP/fzf-input")" \
    '* alpha' \
    'picker marks running sessions with a star'
assert_contains \
    "$(cut -f 2 "$TEST_TMP/fzf-input")" \
    '  bad' \
    'picker leaves inactive configured sessions unstarred'

export T_COLUMNS=120
"$T_BIN"
assert_contains \
    "$(grep "^alpha"$'\t' "$TEST_TMP/fzf-input")" \
    $'windows\t' \
    'wide picker includes a running window count'
assert_contains \
    "$(grep "^alpha"$'\t' "$TEST_TMP/fzf-input")" \
    "$TEST_TMP/alpha" \
    'wide picker includes a configured root directory'

export T_FZF_BIN="$TEST_TMP/bin/does-not-exist"
assert_command_fails 'missing fzf fails only picker mode' "$T_BIN"
"$T_BIN" alpha
pass 'named existing session works without fzf'

unset T_FZF_BIN T_FZF_CAPTURE T_COLUMNS
export T_FAIL_AFTER_SESSION_CREATE=1
assert_command_fails \
    'forced failure after tmux creation is reported' \
    bash -c "cd '$TEST_TMP/plain' && '$T_BIN' cleanup_probe"
unset T_FAIL_AFTER_SESSION_CREATE
assert_session_absent cleanup_probe 'forced failure cleans up incomplete session'

printf '1..%d\n' "$ASSERTIONS"
