#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd "$TEST_DIR/.." && pwd -P)
SOCKET="tmux-host-context-test-$$"
ASSERTIONS=0

tmux_test() {
    command tmux -L "$SOCKET" "$@"
}

cleanup() {
    tmux_test kill-server 2>/dev/null || true
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

tmux_test -f "$REPO_ROOT/tmux.conf" new-session -d -s host-context

expected_color=$($REPO_ROOT/bin/host-color "$(hostname -s)")
actual_color=
for _ in {1..40}; do
    actual_color=$(tmux_test show-options -gv @host-color)
    [[ $actual_color == "$expected_color" ]] && break
    sleep 0.05
done
assert_equal "$expected_color" "$actual_color" 'tmux loads the shared hostname color'

status_left=$(tmux_test show-options -gv status-left)
assert_contains "$status_left" '#{@host-color}' 'status-left consumes the cached host color'
assert_contains "$status_left" '#{host_short}' 'status-left always includes the short hostname'
assert_contains "$status_left" '#{==:#{user},michael}' 'status-left checks for the implied username'

short_host=$(hostname -s)
assert_equal "$short_host" "$(tmux_test display-message -p -F '#{?#{==:michael,michael},,michael@}#{host_short}')" 'michael format suppresses the username'
assert_equal "alice@$short_host" "$(tmux_test display-message -p -F '#{?#{==:alice,michael},,alice@}#{host_short}')" 'other-user format includes user@'

expanded_status=$(tmux_test display-message -p -F '#{E:status-left}')
assert_equal "#[fg=colour$expected_color]$short_host#[default]" "$expanded_status" 'expanded local status has the expected host identity and color'

printf '1..%d\n' "$ASSERTIONS"
