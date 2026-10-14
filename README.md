# /spec: a spec-driven change loop for Claude Code

A Claude Code skill that takes every change to a codebase through one
loop: understand, propose, build test-first, review, update specs and
docs, verify on the device, ship. The change folder keeps the plan and
its progress on disk, so the work survives a context reset or a new
session.

It comes with [ponytail](https://github.com/DietrichGebert/ponytail)
by DietrichGebert, a skill that makes the agent work like a lazy senior
developer: the smallest change that fully solves the task, and a reply
a busy human understands in one read. It applies these best practices
to every change:

- Build only what is needed; skip features, options and flexibility
  nobody asked for.
- Reuse what the codebase already has, then the standard library or
  platform, then an installed dependency; never add a dependency for a
  few lines.
- No abstraction, wrapper, config or "for later" code nobody asked
  for; deletion beats addition; keep the structure the codebase has.
- Fix a bug at its root, once, after checking every caller.
- Finish every part the change needs, including the callers, tests and
  fixtures it breaks; new logic leaves one small test.
- Never cut validation, error handling that prevents data loss,
  security or accessibility.

At its `ultra` level it also pushes back on any part of the request
the need does not justify.

It grew out of [Meditate](https://github.com/janekbt/MeditationApp),
where it runs every change, and works with any language or stack.

## What it does

- **Specs with proof.** Behaviour is written as requirements with
  WHEN/THEN scenarios in `openspec/`, in
  [OpenSpec](https://github.com/Fission-AI/OpenSpec)'s file format
  (the OpenSpec CLI is not needed). Each scenario names the test that
  proves it, or says why only a person can check it.
- **Gates.** Nothing is built before the human approves the proposal.
  Nothing is committed before the human tested it.
- **Test first.** Every scenario's test is written and seen failing
  before the code that passes it.
- **Fresh eyes.** A fresh agent reads the proposal for open questions
  before you see it. Another one reviews the finished change from
  `reviewer-prompt.md`, without the conversation. Fixes that change
  behaviour, data or sync get a new fresh reviewer, round after round,
  until no more fixes that change behaviour are needed.
- **Smallest complete change.** [ponytail](https://github.com/DietrichGebert/ponytail)
  runs through every step and cuts what the need does not justify.
- **One place for the state.** `tasks.md` in the change folder holds
  the checklist, review findings, test steps for the human and the
  proposed commit message.

## Files

| File | What it is |
|---|---|
| `spec/SKILL.md` | The loop: the seven steps, their gates and rules |
| `spec/formats.md` | The file formats: living specs, change folder, deltas, tasks.md, archive |
| `spec/reviewer-prompt.md` | The brief for the fresh review agent |
| `ponytail/SKILL.md` | ponytail's core skill by DietrichGebert, unchanged, with its own `LICENSE` |
| `scripts/check-specs.sh` | Checks that every test named in a spec exists (`--self-test` checks the checker) |

## Install

**1. The skills and the checker**, in the project you want to use it in:

```sh
git clone https://github.com/janekbt/spec-skill.git /tmp/spec-skill
mkdir -p .claude/skills scripts openspec/specs openspec/changes/archive
cp -r /tmp/spec-skill/spec /tmp/spec-skill/ponytail .claude/skills/
cp /tmp/spec-skill/scripts/check-specs.sh scripts/
scripts/check-specs.sh --self-test
```

ponytail comes with it, nothing else to install. To have both skills
in every project, copy `spec/` and `ponytail/` to `~/.claude/skills/`
instead. The checker and `AGENTS.md` still belong in each project.

**2. `AGENTS.md`** at the project root. The skill reads it first and
takes everything project-specific from it.

> **Write this file for your own project.** The template below only
> shows the shape. Every entry in it is an example: the `core/` and
> `web/` parts, the `cargo` commands, the branch, the issue list.
> Replace them with your project's parts, your own test and lint
> commands, your branch and your rules. Keep the section headings, the
> `scripts/check-specs.sh` line and the `/compact` line (with your
> level, if you chose `full`).

```markdown
# AGENTS.md

## Parts
(example: replace with your own)
- `core/`: shared logic; decisions go here
- `web/`: the browser front end
(one line per part a change can reach: apps, platforms, services)

## Hard rules
- (what must never happen, e.g. no lint suppressions, every UI string
  in every translation)

## Commands
(example: replace the cargo lines with your own test and lint commands)
    cargo test --workspace            # tests
    cargo clippy -- -D warnings       # lints
    scripts/check-specs.sh            # every test named in a spec exists

## Branch
Ship to `main`.

## Protected build environment
(files no change may touch without asking, or "none")

## Issue list
`ISSUES.md` (or: GitHub issues)

## Doc map
| When this changes | Update |
|---|---|
| Behaviour of an area | `openspec/specs/<area>/spec.md` (through the change's deltas) |

## Ponytail level
ultra

After every `/compact`, run `/ponytail ultra` again before anything else.
```

**3. Use it.** Start a change in Claude Code with
`/spec <the idea in a few words>` or `/spec <issue numbers>`.

## Ponytail level

/spec turns ponytail on before step 1. The level is `ultra` unless
`AGENTS.md` says `full` under "Ponytail level".

Keep the `/compact` line from the template: a compaction drops the
skill's rules from the agent's context, and `AGENTS.md` is the one file
that is read again after it. Tested: with the line, the agent restarts
ponytail as its first step after `/compact`; without it, it only remembered
the level and worked without the rules.

`ultra` is strongly recommended. `full` keeps the code small; `ultra`
also questions the request itself, which is where the biggest savings
are: the part that never gets built needs no tests, no review and no
fixes.

## Test names in other languages

`check-specs.sh` counts a test as present when its name is followed by
`(`, which fits Rust, Python, Go, Java, C# and most others. If your
tests are named by strings (Jest, RSpec), set a pattern with `%s` for
the name:

```sh
SPEC_TEST_PATTERN='it\("%s"' scripts/check-specs.sh
```

## License

MIT, see [LICENSE](LICENSE). Credits for ponytail and OpenSpec are in
[NOTICE](NOTICE).
`ponytail/` is under its own MIT License, see
[ponytail/LICENSE](ponytail/LICENSE).
