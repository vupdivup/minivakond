---
name: create-issue
description: Opens a GitHub issue with a root cause analysis and a proposed fix. Use when the user says "open an issue", "file a bug", "create an issue", "log this", "track this" or reports a problem or idea to record for later.
---

# Create issue

The user invoking this skill counts as asking to open the issue. Create it directly; don't show a draft first.

## 1. Understand the problem

- Restate the problem in one sentence. If the report is too vague to investigate, ask one short question.
- Check for duplicates: `gh issue list --state all --search "<keywords>"`. If a match exists, show it to the user and ask whether to comment there instead.

## 2. Find the root cause

Don't stop at the symptom. Read the code before writing the issue.

- Locate the relevant code. Use the project CLAUDE.md for the layout.
- Trace why the behavior happens: which line, instruction or missing case causes it. Use `git log -p` / `git blame` if history explains it.
- Quote the exact lines. For prompt or skill files, the cause is often wording: an ambiguous rule, a missing case or two conflicting instructions.
- Separate facts you verified from guesses. If the cause stays unknown, say so and list what to check next.
- For enhancements, "root cause" means the gap: what is missing today and where it would go.

## 3. Propose a fix

- Describe the concrete change: which files and what edit. Small snippets are fine.
- If you can think of other real solutions, add them too. One solution is fine; don't invent weak ones to fill the list.
- With several options, give each one's trade-offs and mark the best as recommended, with one sentence on why.
- Note side effects: version bumps, migrations, breaking changes for users. Check the project CLAUDE.md for such rules.
- Don't implement the fix unless the user asks.

## 4. Write the issue

Title: short and specific, no prefix like `bug:`.

Body (English, Markdown):

```markdown
## Problem
What happens vs. what should happen. Repro steps if relevant.

## Root cause
Explanation with file:line references and quoted lines.

## Proposed fix

### Option A (recommended): <short name>
The change and trade-offs. Why this is the best option.

### Option B: <short name>
The change and trade-offs.

Side effects that apply to all options.
```

Put the recommended option first. With only one option, drop the subheadings.

Add a `## Context` section only when extra context helps (logs, user quotes, environment).

## 5. Label

Use exactly one type label. Do not create new labels.

| Label | When |
|---|---|
| `bug` | Something that exists doesn't work as intended. |
| `enhancement` | New capability or improvement to existing behavior. |
| `documentation` | Only docs change (README, CLAUDE.md, comments). |
| `question` | Open question or decision to discuss, no clear fix yet. |

To close duplicates or rejected issues, use `gh issue close --reason "not planned" --comment "Duplicate of #<n>"`, not labels.

## 6. Create

```
gh issue create --title "<title>" --label <label> --body-file <tmp-file>
```

Write the body to a temp file first to keep Markdown and backticks intact. Then give the user the issue link and a short summary (title, label, recommended option), so they can check it and edit it on GitHub if needed.
