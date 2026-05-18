# Contributing

Thanks for contributing to the CARP study app. This guide covers how to propose changes; it does not cover local environment setup (see the README for that).

## Branching

- `master` — released code; tagged versions are cut from here.
- `develop` — integration branch. **Open all PRs against `develop`.**
- Feature branches — named `feature/<short-description>`, `fix/<short-description>`, or `chore/<short-description>`.

## Flutter version

This repo pins the Flutter SDK with [FVM](https://fvm.app/). The version is declared in `.fvmrc` and **must** be used for development and CI so builds are reproducible. Run Flutter commands as `fvm flutter ...`.

## Commit messages

- Use the imperative mood ("add X", "fix Y", not "added X").
- Keep the subject under 72 characters.
- Reference an issue in the body when relevant (`Refs #123`, `Closes #123`).

## Pull requests

Before opening a PR:

1. Rebase on the latest `develop`.
2. Run `fvm flutter analyze` and `fvm dart format .` — both must be clean.
3. Run `fvm flutter test` — all tests must pass.
4. Build and smoke-test the change in at least the `local` and `dev` deployment modes (see `launch.json`). Note in the PR description which modes you tested.

When opening the PR:

- **Title** — short and descriptive, prefixed with the change type: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`. Example: `fix: handle null study id during consent`.
- **Description** — what changed and *why*. Link the issue it resolves. Call out any user-visible behavior change, migration concern, or risk to other deployment modes.
- **Scope** — one logical change per PR. Split unrelated fixes into separate PRs.
- **Screenshots / recordings** — required for any UI change.
- **Reviewers** — request at least one reviewer from the core team.

## Code style

- Dart formatter line length: 120 (configured in `analysis_options.yaml`).
- Follow the lints in `analysis_options.yaml`; do not suppress warnings without a comment explaining why.
- Prefer small, focused widgets and pure functions; avoid adding state to a widget when a parent already owns it.

## Reporting issues

Bugs and improvement suggestions go through the GitHub issue templates in `.github/ISSUE_TEMPLATE/`. Do not file security issues in public issues — see `SECURITY.md` if present, or email the maintainers directly.
