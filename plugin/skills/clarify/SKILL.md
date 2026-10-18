---
name: clarify
description: Resolves ambiguities in how the data should be interpreted, and records the answers permanently as business rules. Examples are which column is the real measure, which rows count, which date to use, or how categories roll up. Use when an ambiguity would change an answer, after ingesting data with open issues, or when the user says "let's set up the rules", "check my definitions", "review my data", "nézzük át a szabályokat", "mit jelent ez az oszlop", "nézd át az adataimat", "rögzítsük, hogy…".
---

# Clarify business rules

You're a sharp analyst interviewing a domain expert. They know the business; you know where data goes wrong. Respect their time. Follow the `workspace` skill's conventions (load it first if it isn't loaded yet). In particular, speak in the user's language.

This skill works for any kind of data. Don't bring a domain checklist; find the ambiguities in the data itself, using the lenses below.

## When to ask

- **Ask** when the ambiguity would change a number the user will see.
- **Don't ask** about anything already in `rules/business_rules.md`, or anything with no material effect on results. Mention a minor assumption in the answer instead.
- **Proactive review** (when the user asks for it): go through every dataset with the categories below, plus definitions their recent questions relied on.

## Where ambiguity hides

Use these as lenses, not as a questionnaire. For each one, run a query to see whether the problem actually exists in this data. Only ask about the ones that do, ordered by how much they change the numbers.

1. **Grain and double counting.** What is one row? Does the file mix versions or states (plan vs. actual, original vs. correction, total rows next to detail rows) that double count when summed?
2. **Which measure.** Gross vs. net, ordered vs. delivered, list vs. paid. What do negative values mean?
3. **Which rows count.** Statuses, test records, internal transactions, outliers.
4. **Time.** Which date defines the period; how records spanning periods split; fiscal vs. calendar year; snapshot date.
5. **Categories and entities.** Inconsistent spellings; rollups the user thinks in; attributes that change over time (value at the event, or current value?).
6. **Units and scale.** Mixed currencies, values in thousands, percentages as 0–1 vs. 0–100.
7. **Empty values.** Zero, unknown, or not applicable?
8. **Coverage and denominators.** Who or what is *not* in the file? If it lists only items that had an event, the zeros are missing, so rates and averages need another file. Say so plainly.
9. **Relationships between datasets.** Linking key, one-to-many matches, unmatched rows.

### Cleanup vs. rules

- **Purely mechanical cleanup** (trailing spaces, obvious case differences) doesn't need a question. Fix it in the view and mention it once.
- **Anything that involves judgement is a question.** For example, whether "1 .raktár" and "1. raktár" are the same, or how to group things.

## How to ask

1. **Measure before asking.** Run a query to show what is at stake, with numbers formatted for the user's locale. For example: "If we add up both kinds of rows the total is 10 402; counting only one kind it's 5 139." A question with numbers attached is much easier to answer.
2. **Use AskUserQuestion** with concrete options. Use the user's language and business terms. Put your recommendation first, with the recommended-option suffix from the workspace skill.
3. If the user doesn't know or wants to decide later, record the item under *Nyitott kérdések* (open questions) with the assumption you'll use meanwhile.

## How to record (immediately, before using the answer)

Change both files with the Edit tool, never from the shell.

1. **`rules/business_rules.md`** (in Hungarian):
   - Add the rule under *Definíciók és szabályok* (definitions & rules) with the next free ID: `**R-00N Name** — rule in plain words. Confirmed: <date>.`
   - If the user used a word of their own for the concept, add it to the *Szótár* (glossary) with its meaning and internal column name. From then on, use exactly that word in all answers and reports.
   - Add a line to the *Döntésnapló* (decision log).
   - Remove the item from *Nyitott kérdések* if it was there.
   - If the rule replaces an older one, mark the old one as superseded by the new ID. Don't delete it.
2. **`rules/views.sql`** (if the rule affects calculations): update the relevant `v_*` view and tag each affected line with `-- R-00N`.
   - Prefer adding derived columns and filters over renaming things.
   - Views may build on other views, and may join datasets once the user has confirmed how they relate.
3. **Rebuild and verify:** run `./tools/duckdb.exe data/work.duckdb -f data/build.sql`, then run a quick query showing the rule took effect (e.g. the new total).
4. Confirm to the user in one line, naming the rule ID.

General preferences the user states (e.g. how they like numbers shown) go under *Beállítások* (preferences). They don't get an R-ID.
