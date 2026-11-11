#!/usr/bin/env bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

failed=0
while IFS= read -r -d '' path; do
    case "/$path/" in
        */journal/*|*/journals/*)
            printf 'Public-content check: journal file is tracked: %s\n' "$path" >&2
            failed=1
            ;;
    esac
done < <(git ls-files -z)

# Report filenames only; private note text/IDs must not enter public CI logs.
private_links='https?://[^[:space:]"<>]+/#root/[^[:space:]"<>]+|trilium://note/'
set +e
linked_files=$(git grep --cached -I -l -E "$private_links" -- . ':!tests/public_content_test.sh')
link_status=$?
set -e
if (( link_status == 0 )); then
    printf 'Public-content check: private note links in:\n%s\n' "$linked_files" >&2
    failed=1
elif (( link_status != 1 )); then
    printf 'Public-content check: could not inspect staged content.\n' >&2
    exit "$link_status"
fi

if (( failed != 0 )); then
    printf 'Keep journals and private note context in Trilium. See AGENTS.md.\n' >&2
    exit 1
fi

printf 'Public-content check passed.\n'
