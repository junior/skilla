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

**Managed — [Homebrew](https://brew.sh) (macOS/Linux):**

```bash
brew install junior/tap/skilla
```

**Managed — [mise](https://mise.jdx.dev):**

```bash
mise use -g 'github:junior/skilla[exe=skilla,matching=skilla]@0.2.1'
```

**Quick — fetch the single script onto your PATH:**

```bash
curl -fsSL https://raw.githubusercontent.com/junior/skilla/v0.2.1/skilla \
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
  --scope <user|project>  project = ./.agents/skills/ (default); user = ~/.agents/skills/
  -g, --global         Shorthand for --scope user
  --path <dir>         Install into a custom directory (e.g. .claude/skills)
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
skilla add --scope user git@github.com:acme/skills.git # into ~/.agents/skills (-g works too)
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
| `--scope project` (default) | `./.agents/skills/` | `./.agents/registry.json` |
| `--scope user` (or `-g`) | `~/.agents/skills/` | `~/.agents/registry.json` |
| custom (`--path DIR`) | `DIR` | `DIR/../registry.json` |

## Use skilla from your AI CLI (the `skilla` skill)

This repo also ships a **skill named `skilla`** (`skills/skilla/SKILL.md`,
[agentskills.io](https://agentskills.io/specification) format) that teaches an AI CLI —
Claude Code, Devin, Cursor, anything that reads agent skills — to install and manage
skills **through skilla** instead of its vendor-specific mechanism. Install it once and
"install the nginx skill from <repo>" just works inside the agent:

```bash
# for the current project (Devin indexes .agents/skills/):
skilla add https://github.com/junior/skilla --skill skilla

# user-wide:
skilla add --scope user https://github.com/junior/skilla --skill skilla

# for a Claude Code project (its skills dir):
skilla add --path .claude/skills https://github.com/junior/skilla --skill skilla
```

## Development

```bash
bash tests/test.sh     # self-contained: builds a fixture catalog, asserts install + deps
shellcheck skilla tests/test.sh
```

## License

[MIT](LICENSE)
