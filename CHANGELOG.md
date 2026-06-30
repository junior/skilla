# Changelog

All notable changes are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versioning is SemVer.

## [Unreleased]

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
