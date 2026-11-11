# Working on this public repository

This repository is public. Publish reusable configuration, technical
documentation, and concise technical issue scope here.

## Journals are private

- Write session journals, activity recaps, personal context, investigations,
  and resume notes **only in private Trilium notes**.
- Never commit journal entries under any filename or directory. Do not put
  personal session history in commit messages, GitHub issues, pull requests,
  comments, or tracked documentation either.
- Keep private Trilium note URLs/IDs and excerpts out of public content.
  Public issues should stand alone as technical requirements; their private
  context stays in Trilium.
- This rule overrides generic journal/bootstrap skill defaults. When using
  `track-project-journal`, save its journal output to private Trilium.
- If Trilium is unavailable, report that the private journal is pending.
  Do not fall back to a file in this checkout or a public GitHub write.
- Preserve Git history unless the user explicitly requests otherwise.

## Before committing

Read `README.md`, `TODO.md`, and the current Git state. Retrieve private context
from Trilium only when relevant; there is no repository journal to consult.

Enable the local privacy guard with `git config core.hooksPath .githooks`.
If custom hooks already exist, preserve them and chain the public-content check.
Run `bash tests/public_content_test.sh` against the staged index before a commit.
The check rejects tracked journal directories and private note links; it is a
guardrail, not a substitute for reviewing prose for personal details. Do not
bypass it to publish private material. CI runs the same check.

Use authenticated local `gh` for GitHub operations, never a GitHub connector.
Keep `TODO.md` synchronized with the technical issues it indexes.
