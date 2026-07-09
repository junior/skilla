# Changelog

All notable changes are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versioning is SemVer.

## [Unreleased]

## [0.2.0] - 2026-07-08
### Added
- `--scope <user|project>` — the explicit way to pick where skills live
  (`project` = `./.agents/skills/`, the default; `user` = `~/.agents/skills/`).
  `-g/--global` is now shorthand for `--scope user`.
- **The `skilla` skill** (`skills/skilla/SKILL.md`) — an agentskills.io skill that
  teaches AI CLIs (Claude Code, Devin, ...) to install/manage skills via skilla;
  self-hosted: `skilla add <this-repo> --skill skilla`.
- Homebrew tap: `brew install junior/tap/skilla`.
### Changed
- Help output uses the plain `skilla` name instead of the invocation path
  (`$0`) everywhere, with a single `Location:` line showing where the script lives.
- `list` labels the scope `user` (or `custom path`) instead of `global`.
### Fixed
- `verify` uses the cosign v3 bundle API (`--bundle`, default `<artifact>.bundle`).

## [0.1.0] - 2026-06-29
### Added
- Install agentskills.io skills from git repos: `add`, `update`, `list`, `info`, `remove`.
- Project / global / custom (`--path`) scopes with a JSON registry.
- Dependency resolution: a skill's `requires:` (frontmatter) / `requiredSkills`
  (`plugin.json`) are installed from the same source (transitive closure).
- Version resolved from `SKILL.md` frontmatter (`plugin.json` fallback, then commit hash).
- `--check` dry-run, `--force` reinstall, `-s/--skill` single-skill, `version` / `--version`.
- Single-pass argument parser (value flags no longer swallow following flags),
  portable UTC timestamps, and `set -e`-safe control flow.
