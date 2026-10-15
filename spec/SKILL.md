---
name: spec
description: Use when starting any change to the project's code or behaviour - a bug fix, one item from the issue list or a batch of them, a feature, or a refactor beyond a single file. Invoked as /spec <issue numbers, or the idea in a few words>.
---

# /spec: one change, from plan to commit

Every change to the project goes through this loop. Specs say what the
software does; tests prove it; the change folder is the memory that
survives a context reset, so keep it current as you go, not at the end.

Violating the letter of these rules is violating their spirit.

File formats: [formats.md](formats.md). Review brief:
[reviewer-prompt.md](reviewer-prompt.md). Project rules, commands, the
parts of the project and the doc map: `AGENTS.md`.

## Ponytail first

This skill runs with ponytail (github.com/DietrichGebert/ponytail),
which ships next to it in `ponytail/`; it keeps every step to the
smallest complete change. The level is `ultra` unless `AGENTS.md`
names `full` under "Ponytail level". `ultra` is strongly recommended:
it also pushes back on the request itself. When to call it: step 1.

## Size first

| The change | What it needs |
|---|---|
| Typo, comment, doc-only, a fix to an existing translation | No change folder. Steps 5 to 7 still apply. |
| Anything that changes what the software does, or touches more than one file | The full loop. |
| A batch of items from the issue list | One change folder for the batch; the proposal lists the issue numbers. |

Changed user-visible text is behaviour, not a translation fix. Unsure?
Use the full loop. Only the maintainer saying explicitly "skip /spec"
skips it, for that one change; "it's tiny" is not that. Say in one line
what the size table asks for and offer the short form below.

The short form, for a small behaviour change: a proposal of about five
lines, one delta with the scenarios it needs, a tasks.md with the loop
checklist and one task per scenario. The steps and gates stay the same.

## The loop

Keep the checklist at the top of `tasks.md` and tick each step when
it is done. A skipped step stays unticked with its reason on the line.

### 1. Understand

- The first tool call of every /spec run is `/ponytail <level>` (Skill
  tool, `ponytail`, args `<level>`; `ponytail:ponytail` where the plugin
  is installed). Every run, also when ponytail looks active: a level set
  earlier or by a session hook may not be this one, and a `/compact`
  resets it. Tick step 0 in `tasks.md`.
- Read `AGENTS.md`, the living spec of every area the change touches
  (`openspec/specs/<area>/spec.md`), and the issue entries.
- Re-check each issue against the current code: does it still happen,
  are the line numbers right? An issue that is already fixed gets a test
  that proves it and leaves the list.
- Record the base: `git rev-parse HEAD` goes into `tasks.md`. The working
  tree must be clean; if it is not, ask what the uncommitted work is.
- Run the test suites on the base and note the result next to it. A
  later failure is then yours, not an older one; a red base is told to
  the human before anything is built.
- Say back what you understood before you plan: in two or three
  sentences, name the screen or interface, the element and what changes
  on it, on every part of the project that has it. Wait for "yes" or a
  correction.
- Then settle every decision only the human can make (how it looks,
  its wording, a real trade-off), one per message, as a multiple-
  choice question with 2 to 4 concrete options and your recommendation
  first (Claude Code: AskUserQuestion). Answer from the code what the
  code can answer. Minor choices are your call; mark them as such in
  the proposal. A UI change with more than one sensible layout gets a
  mock-up to react to.
- End with the list of decisions; it goes into proposal.md.

### 2. Propose

Write the change folder (`openspec/changes/<kebab-name>/`, see
formats.md):

- `proposal.md`: why, what changes, every place it must reach.
- Spec deltas: each behaviour as a requirement with WHEN/THEN scenarios,
  each scenario with the test that will prove it.
- `tasks.md`: the checklist, Review Focus, then the tasks.
- `design.md` only for a schema, sync or wire-format change, or a new
  dependency.

Push back on scope before showing it: drop every part the need does not
justify and say what you dropped in one line. A plan is the set of
decisions the implementer cannot make alone; a plan longer than the code
it describes has written the code instead.

Self-review before showing it:
1. Every issue or request maps to at least one scenario.
2. Every scenario names its test, and a reviewer who never saw the code
   could tell whether it passed.
3. Every place it must reach is listed: each part of the project named
   in `AGENTS.md`, translations, docs, migration, the protected build
   environment.
4. Review Focus names the inputs the scenarios are silent on (a second
   device or user, a replayed event, old data, a deleted record, an
   empty list, another language), and each one got a scenario or a
   reason.
5. No "TBD", no "handle edge cases", no step that says what without how.

Then, for every change that has a change folder, give the folder to a
fresh agent before showing it: "You are a senior developer who must
build this without talking to its author. List only the questions where
a wrong guess would matter." Answer what the files already answer,
decide the minor ones yourself (mark them as your call in `tasks.md`),
and bring the rest to the human once.

```
HARD GATE: nothing is built until the human has read the proposal and
said go. Building includes tests, scaffolding and "just trying it".
Approval covers what you showed, nothing else.
```

### 3. Build, test first

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.
Code written before its test is deleted, not kept as a reference.
The only exception is a throwaway spike the human approved as one.
```

For each scenario, in the order of `tasks.md`:

1. Write the test the scenario names. Expected values are written by
   hand, never computed by the code under test.
2. Run it and watch it fail for the right reason. A compile error is not
   a failure; make it compile with a stub first. A test that passes at
   once either tests nothing or the behaviour already exists. Find out:
   make the smallest edit to the production code (never the test) that
   breaks the behaviour, run, restore. Still passing: rewrite the test.
   Failing: note in `tasks.md` that the behaviour existed, and if the
   plan assumed it was missing, re-check the proposal; if what you build
   changes, ask.
3. Write the least code that passes it. On every part of the project
   that has the behaviour; shared decisions go in shared code, not in
   one front end.
4. Run the whole suite, not just the file. A failure you saw and did
   not report is a false report.
5. Tick the task in `tasks.md`.

The spec is a hypothesis that building tests. A case the plan missed
(found while building, by a review or on the device) goes into the
deltas as a scenario with its test before its code, like every other.
If it changes what the human approved, ask first.

A test is good when you can name the production change that would make
it fail. No tests that only restate the code (change detectors), none
that test the framework, none that read source text unless the code
cannot run on the test host.

When something breaks you don't understand: find the cause before
fixing anything. Reproduce it, read the whole error, check what changed,
add logging at each boundary (UI, shared code, storage, network) until
you see where it goes wrong, then state "X is the cause because Y" and
test that one idea. After three fixes that didn't work, stop and talk
to the human: the design is probably wrong, not the fix.

### 4. Review

Start a fresh agent with [reviewer-prompt.md](reviewer-prompt.md), the
change folder path and the base commit. Give it files, never this
conversation, and never tell it what not to flag.

A schema, sync or wire-format change gets two fresh agents in parallel
instead, each with the brief plus one of its two focus lines (data and
sync; completeness and rules). Two focuses find more than the same
review twice.

For each finding: check it against the code yourself. Fix what holds,
one at a time, with a test where it is behaviour. A finding you reject
gets one line in `tasks.md` (what, why) and is shown to the human. A
finding that would change behaviour, UI text or data beyond the approved
proposal is a question for the human, not a fix.

Fixes are code no reviewer saw. When the fixes after the review, or
after the device test in step 6, change behaviour, data or sync, a
fresh agent reviews only those: give it the list of fixes from
`tasks.md`, the files and the brief, and fix what it finds the same
way. Fixes to wording, comments or docs need no second look.

### 5. Specs, docs and the list

- Run `scripts/check-specs.sh`: every test named in a spec exists.
- Update every doc the change made wrong, using the doc map in
  `AGENTS.md`. Grep the docs for the names you changed.
- The issue list: remove the fixed items, tick a finished batch.

### 6. Verify and hand over

Claim nothing you have not just seen:

| Claim | Needs | Not enough |
|---|---|---|
| Tests pass | the full suite's output, read to the end | an earlier run, one file |
| Lints clean | every linter `AGENTS.md` lists, zero warnings | "it compiled" |
| Built | the artifact's new timestamp or hash | "Finished in 15s" |
| Fixed | the original symptom, reproduced and now gone | the test passing |
| Works on the device | the human said so | the build succeeding |

Build what the human tests on and give them test steps: what to do,
what they should see, for each scenario that only a person can check.
Write the test steps, the artifact paths and the proposed commit message
into `tasks.md` too, so a new session can ship once the human approves.

```
HARD GATE: no commit, not even a local one, before the human tested
and approved. "Tests are green" is not approval. An instruction to
ship ("finish it up", "push it tonight") given before they tested is
not approval either: reply with the test steps and wait.
```

### 7. Ship

1. Merge the deltas into the living specs (formats.md, "Archive"), move
   the change folder to `openspec/changes/archive/YYYY-MM-DD-<name>/`, run
   `scripts/check-specs.sh` again.
2. Show the commit message; commit and push to the branch `AGENTS.md`
   names once approved, in one commit with the code, the specs and the
   archived folder. A contributor without push rights opens a pull
   request instead, after step 6, and the maintainer tests and merges it.

## Stop and ask before

- a schema or wire-format change (it needs a migration, tested against
  data from the last release);
- touching the build environment `AGENTS.md` protects;
- adding a dependency;
- deleting files or user data;
- any change to behaviour, UI text or data that the approved proposal
  does not cover;
- a commit or a push.

## What you will tell yourself

| The thought | The truth |
|---|---|
| "Ponytail is already on." | Maybe at another level, maybe not since the `/compact`. Call it, every run. |
| "I know what they mean." | Say it back first. A wrong guess costs a whole proposal. |
| "Too small for a change folder." | Small changes skip the most steps and break the most rules. Use the size table. |
| "The tests are green, I'll commit and the human tests later." | No commit before the device test. Hard gate. |
| "I'll update the docs and specs at the end." | The end is when they get forgotten. Step 5 is before the hand-over. |
| "The other platform can follow later." | Every part that has the behaviour, in the same change, or a written reason the human approved. |
| "The test passed first time, good." | Either it tests nothing or the behaviour existed. Find out which. |
| "It built." | Stat the artifact. |
| "The reviewer found nothing, so it's right." | The review is one check of several; step 6 still applies. |
| "They said go earlier." | Approval covers what you showed. New scope needs a new go. |
| "A lint suppression silences it." | Fix the cause. |
| "I followed the spirit of the rule." | The letter is the spirit. |
