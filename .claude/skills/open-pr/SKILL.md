---
name: open-pr
description: Opens a GitHub pull request for the current branch. Checks the branch, fixes stale docs in a separate commit, links or closes related issues, and writes a conventional-commit title and a short body. Use when the user says "open a PR", "create a pull request", "make a PR", "push and PR" or "ship this branch".
---

# Open PR

The user invoking this skill counts as asking for the commits, push and PR below. Ask before anything else that changes shared state, such as force-pushing or editing issues.

The repo allows only squash merges, so the PR title becomes the commit message on `main`.

## 1. Check the branch

- Run `git fetch origin`.
- If the current branch is `main`, create a branch named from the change (`feat/…`, `fix/…`, `docs/…`) and switch to it.
- If `gh pr view` finds an open PR for this branch, stop and give the user its link. Offer to update its title or body instead.
- If the working tree has uncommitted changes, commit the ones related to this branch's work without asking. Use a conventional commit message. Leave unrelated changes uncommitted and tell the user about them.
- List the changes: `git log origin/main..HEAD --oneline` and `git diff origin/main...HEAD --stat`. If there are no commits, stop and tell the user there is nothing to open.
- If the branch is behind `origin/main`, rebase it onto `origin/main`. If the rebase has conflicts, abort it and ask the user.

## 2. Check the change

Read the full diff: `git diff origin/main...HEAD`.

- If anything under `plugin/` or `.claude-plugin/` changed, run `claude plugin validate .` and `claude plugin validate plugin`. Both must print `Validation passed`. If either fails, stop and show the error.
- Changed text files must be UTF-8 without BOM. Check that no changed file starts with the bytes `EF BB BF`.
- Do not bump `version` in `plugin.json`. The `release` skill bumps it in its own PR.
- Look for leftovers: debug output, commented-out code, TODOs added by this branch, and files that do not belong to the change. Mention them to the user; do not remove them without asking.

## 3. Fix stale docs

Check the project `CLAUDE.md` and every `README*` file against the code as it is after this branch. A statement is stale when it is now false. Examples: a renamed or removed file, folder, skill or command, a changed convention, or a layout description that no longer matches.

- Only correct or remove stale statements. Do not add documentation for new things the branch introduces, even if it seems missing. Mention such gaps to the user instead.
- Keep the existing wording and structure. Change only what is false.
- `plugin/skills/setup/assets/CLAUDE.md.tmpl` is product content, not dev docs. Do not touch it in this step.
- If you corrected anything, commit it separately with `docs: fix stale info in <file>`. Do not mix it with other changes.
- If nothing is stale, skip this step silently.

## 4. Find related issues

- List open issues: `gh issue list --state open --limit 100 --json number,title,body,labels`.
- Compare each issue with the diff, not only with the commit messages.
  - **Fixes**: the branch fully solves the issue. Add `Closes #<n>` to the body. GitHub closes the issue when the PR merges.
  - **Related**: the branch touches the issue but does not fully solve it. Add `Related: #<n>`. Never use a closing keyword for a partial fix.
- If you are unsure whether an issue counts as fixed, treat it as related and say so to the user.

## 5. Write the PR

Title: a conventional commit, such as `feat: add mock data`. Pick the type from the diff, not from the branch name. Keep it under 70 characters, lowercase after the prefix, no period.

Body (English, Markdown), in this shape:

```markdown
<One or two sentences: what the PR does and why.>

- <Main change>
- <Main change>

Closes #<n>
Related: #<n>

<generated-with footer>
```

- Keep it short. Describe behavior, not every file. Leave out sections that would be empty.
- Mention user-facing effects: workspace upgrade needed, changed skill behavior, breaking changes.
- If step 3 made a docs commit, add one line saying which docs were corrected.
- If the change was not tested in the desktop app, say so in one line.

## 6. Create

- Push: `git push -u origin HEAD`. If the push is rejected after a rebase, ask the user before running `git push --force-with-lease`.
- Write the body to a temp file to keep Markdown and backticks intact, then run:
  ```
  gh pr create --base main --title "<title>" --body-file <tmp-file>
  ```
- Do not open a draft PR unless the user asks. Do not add labels or reviewers.
- Give the user the PR link and list any issues it closes or links.
