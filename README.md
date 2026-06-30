# skilla

A small, dependency-light CLI for installing [Agent Skills](https://agentskills.io/)
from git repositories into the locations agents read them from.

It clones a repo, discovers `skills/<name>/SKILL.md`, resolves declared
dependencies (`requires:`), and installs the skills into a project
(`.agents/skills/`) or your home (`~/.agents/skills/`) — tracking what's installed
in a small JSON registry so it can `list`, `update`, and `remove` cleanly.

> Built to install [agentskills.io](https://agentskills.io/specification) skills for
> agents such as Devin (which indexes `.agents/skills/<name>/SKILL.md`) while staying
> host-agnostic — a drop-in for environments where a vendor plugin manager isn't available.

## Requirements

`bash`, `git`, and [`jq`](https://jqlang.github.io/jq/) (`apt install jq` / `brew install jq`).

## Install

**Managed (recommended) — via [mise](https://mise.jdx.dev):**

```bash
mise use -g 'github:junior/skilla[exe=skilla,matching=skilla]@0.1.0'
```

**Quick — fetch the single script onto your PATH:**

```bash
curl -fsSL https://raw.githubusercontent.com/junior/skilla/v0.1.0/skilla \
  -o ~/.local/bin/skilla && chmod +x ~/.local/bin/skilla
```

## Usage

```text
skilla <command> [options] [arguments]

Commands:
  add <git-url>        Install skills from a repo (with --force to reinstall)
  update [skill]       Update one skill, or all if omitted
  list, ls             List installed skills + versions
  info <skill>         Show a skill's details + declared dependencies
  remove, rm [skill]   Remove a skill (or all with --all)
  version              Print version (also -v, --version)

Options:
  -g, --global         Use ~/.agents/skills/ instead of ./.agents/skills/
  --path <dir>         Install into a custom directory
  -s, --skill <name>   Install only one named skill from the repo
  --force              Reinstall even if present
  --check              Report actions without applying them
  -y, --yes            Auto-confirm prompts
  --all                Apply to all (for remove)
```

### Examples

```bash
skilla add git@github.com:acme/skills.git              # every skill in the repo
skilla add git@github.com:acme/skills.git -s nginx     # one skill (+ its deps)
skilla add -g git@github.com:acme/skills.git           # into ~/.agents/skills
skilla list
skilla info nginx
skilla update nginx
skilla remove nginx
```

## How it works

- **Discovery** — a source repo holds skills at `skills/<name>/SKILL.md` (a repo with a
  single root `SKILL.md` is treated as one skill).
- **Dependencies** — if a skill declares `requires:` in its `SKILL.md` frontmatter (or
  `requiredSkills` in an optional `plugin.json`), those sibling skills are installed
  automatically from the same source (transitive closure).
- **Version** — read from `SKILL.md` frontmatter `version:` (falling back to `plugin.json`,
  then the commit hash).
- **Registry** — installs are recorded in `registry.json` beside the skills dir (`source`,
  `commit`, `version`, timestamps), so `list`/`update`/`remove` are exact and only ever
  touch skills this tool installed.
- **No code runs at install time** — it clones and copies; a skill's own scripts only run
  later when an agent uses it.

## Scopes

| Scope | Skills dir | Registry |
|-------|-----------|----------|
| project (default) | `./.agents/skills/` | `./.agents/registry.json` |
| global (`-g`) | `~/.agents/skills/` | `~/.agents/registry.json` |
| custom (`--path DIR`) | `DIR` | `DIR/../registry.json` |

## Development

```bash
bash tests/test.sh     # self-contained: builds a fixture catalog, asserts install + deps
shellcheck skilla tests/test.sh
```

## License

[MIT](LICENSE)
