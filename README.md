# skill-manager

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

```bash
# clone + symlink onto your PATH
git clone git@github.com:junior/skill-manager.git
ln -s "$PWD/skill-manager/skill-manager" ~/.local/bin/skill-manager

# …or fetch the single script directly (once the repo is public):
# curl -fsSL https://raw.githubusercontent.com/junior/skill-manager/main/skill-manager \
#   -o ~/.local/bin/skill-manager && chmod +x ~/.local/bin/skill-manager
```

## Usage

```text
skill-manager <command> [options] [arguments]

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
skill-manager add git@github.com:acme/skills.git              # every skill in the repo
skill-manager add git@github.com:acme/skills.git -s nginx     # one skill (+ its deps)
skill-manager add -g git@github.com:acme/skills.git           # into ~/.agents/skills
skill-manager list
skill-manager info nginx
skill-manager update nginx
skill-manager remove nginx
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
shellcheck skill-manager tests/test.sh
```

## License

[MIT](LICENSE)
