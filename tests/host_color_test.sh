#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd "$TEST_DIR/.." && pwd -P)
HOST_COLOR="$REPO_ROOT/bin/host-color"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/host-color-test.XXXXXX")
ASSERTIONS=0

cleanup() {
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

viper_color=$($HOST_COLOR viper.mk3.dev)
assert_equal 202 "$viper_color" 'viper maps to orange-red'
assert_equal "$viper_color" "$($HOST_COLOR VIPER.quad5.net)" 'hash uses the lowercased short hostname'

lucifer_color=$($HOST_COLOR lucifer.quad5.net)
[[ $lucifer_color != "$viper_color" ]] || fail 'representative hostnames receive distinct colors'
pass 'representative hostnames receive distinct colors'

approved_palette=' 196 197 198 201 202 208 214 220 135 39 45 82 '
for color in "$viper_color" "$lucifer_color"; do
    [[ $approved_palette == *" $color "* ]] || fail "host color $color belongs to the approved palette"
done
pass 'host colors belong to the approved palette'

assert_equal 208 "$($HOST_COLOR '')" 'empty hostname uses the bright orange fallback'
assert_equal 208 "$(PATH=/path/without/cksum "$HOST_COLOR" viper)" 'missing cksum uses the bright orange fallback'

mkdir -p "$TEST_TMP/bin"
printf '%s\n' '#!/bin/sh' 'printf "invalid output\n"' > "$TEST_TMP/bin/cksum"
chmod +x "$TEST_TMP/bin/cksum"
assert_equal 208 "$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$HOST_COLOR" viper)" 'invalid checksum uses the bright orange fallback'

printf '1..%d\n' "$ASSERTIONS"
