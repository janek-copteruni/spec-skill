# /spec: a spec-driven change loop for Claude Code

A Claude Code skill that takes every change to a codebase through one
loop: understand, propose, build test-first, review, update specs and
docs, verify on the device, ship. The change folder keeps the plan and
its progress on disk, so the work survives a context reset or a new
session.

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
  `reviewer-prompt.md`, without the conversation.
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
takes everything project-specific from it. Start from this:

```markdown
# AGENTS.md

## Parts
- `core/`: shared logic; decisions go here
- `web/`: the browser front end
(one line per part a change can reach: apps, platforms, services)

## Hard rules
- (what must never happen, e.g. no lint suppressions, every UI string
  in every translation)

## Commands
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

MIT, see [LICENSE](LICENSE), which also credits ponytail and OpenSpec.
`ponytail/` is under its own MIT License, see
[ponytail/LICENSE](ponytail/LICENSE).
