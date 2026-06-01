This project is a general research folder. Each folder has its own CLAUDE.md with instructions about what to do there.

This folder is where we keep settings and general things.

## Ruby linting

Ruby is the scripting language for this repo. After editing any `.rb` file, run `rubocop <file>` and fix every offense before moving on.

- Config: `.rubocop.yml` at the repo root.
- A pre-commit hook (`.githooks/pre-commit`) blocks commits that fail `rubocop` on staged `.rb` files. Enable once per clone: `git config core.hooksPath .githooks`.
- Install if missing: `gem install rubocop`.
