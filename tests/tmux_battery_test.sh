#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd "$TEST_DIR/.." && pwd -P)
BATTERY_BIN="$REPO_ROOT/bin/tmux-battery"
UPOWER_FIXTURE="$TEST_DIR/fixtures/upower"
ASSERTIONS=0

assert_output() {
    local expected=$1
    local scenario=$2
    local actual

    actual=$(
        UPOWER_SCENARIO="$scenario" \
            TMUX_BATTERY_UPOWER="$UPOWER_FIXTURE" \
            "$BATTERY_BIN"
    )

    if [[ $actual != "$expected" ]]; then
        printf "not ok - %s (expected '%s', got '%s')\n" \
            "$scenario" "$expected" "$actual" >&2
        exit 1
    fi

    ASSERTIONS=$((ASSERTIONS + 1))
    printf 'ok %d - %s\n' "$ASSERTIONS" "$scenario"
}

assert_output '72% 7:42' discharging
assert_output '72% charging' charging
assert_output '100% full' full
assert_output '' missing-time
assert_output '' missing-battery

actual=$(TMUX_BATTERY_UPOWER=/does/not/exist "$BATTERY_BIN")
if [[ -n $actual ]]; then
    printf "not ok - missing UPower (expected '', got '%s')\n" "$actual" >&2
    exit 1
fi
ASSERTIONS=$((ASSERTIONS + 1))
printf 'ok %d - missing UPower\n' "$ASSERTIONS"

printf '1..%d\n' "$ASSERTIONS"
