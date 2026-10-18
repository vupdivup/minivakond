---
name: release
description: Releases a new version of the Minivakond plugin. Picks the next version, bumps plugin.json through a PR, then tags main so the Release workflow publishes release notes. Use when the user says "release", "cut a release", "ship a new version" or "bump the version".
---

# Release

Releasing has two halves:

1. **Bump**: a PR that changes only `version` in `plugin/.claude-plugin/plugin.json`. Users install from the marketplace on `main`, so merging this PR is what ships the version: `/plugin marketplace update` picks it up.
2. **Tag**: after the PR is merged, push a `v<version>` tag on `main`. The tag triggers `.github/workflows/release.yml`. The workflow checks that the tag matches `plugin.json` and creates a GitHub Release with generated notes.

The user invoking this skill counts as asking for the commit, push and PR below. Confirm with the user before pushing the tag, because the tag publishes the release.

## 1. Pick the version

- Run `git fetch --tags origin`. Find the last tag with `git describe --tags --abbrev=0 origin/main`. If there is no tag yet, the first release is the current `plugin.json` version: skip to step 3 and tag it without a bump.
- List the changes: `git log <last-tag>..origin/main --oneline`. If the list is empty, stop and tell the user there is nothing to release.
- Commit messages don't reliably mark features or breaking changes. Don't infer the version from commit types. Read the actual diff instead: `git diff <last-tag>..origin/main --stat`, then the relevant files.
- Suggest the next version (semver) from what the diff changes:
  - Breaking: existing workspaces or user habits stop working. Examples: a renamed or removed skill, a changed workspace layout, a changed table or file naming convention, or a removed `tools/` script. This is major, but while the version is `0.x`, bump minor instead.
  - New capability: a new skill, a new output type, or new behavior users can use. This is minor.
  - Otherwise (fixes, wording, docs, internal cleanup): patch.
- Show the user a short summary of the changes, the suggested version and the reason. Let the user confirm or choose another version.

## 2. Bump through a PR

- Create a branch from up-to-date main: `git switch -c release/v<version> origin/main`.
- Change only the `version` field in `plugin/.claude-plugin/plugin.json`. Keep the rest of the file byte-for-byte (UTF-8 without BOM, same formatting). Edit the line; do not round-trip the file through `ConvertTo-Json`.
- Run `claude plugin validate .` and `claude plugin validate plugin` as a smoke test. Both must print `Validation passed`.
- Commit with the message `chore: release v<version>`. Push the branch and open a PR with `gh pr create`. In the PR body, list the commits since the last tag.
- Give the user the PR link and ask them to merge it. Wait for the user to confirm the merge.

## 3. Tag

- Run `git fetch origin`. Check that `plugin.json` on `origin/main` has the new version:
  `git show origin/main:plugin/.claude-plugin/plugin.json`. If the version differs, stop: the PR is not merged yet.
- Ask the user to confirm the tag push.
- Tag and push:
  ```
  git tag v<version> origin/main
  git push origin v<version>
  ```
- Watch the workflow: `gh run list --workflow release.yml --limit 1`, then `gh run watch <run-id> --exit-status`.
- When the run succeeds, give the user the release link from `gh release view v<version> --json url`. If the run fails, show the failing step from `gh run view <run-id> --log-failed`. Do not delete or move the tag without asking the user.
