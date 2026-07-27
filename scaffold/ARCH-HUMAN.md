# quick-proj

## What this is

`quick-proj` is a command you run in the terminal. It creates a new coding project folder with a standard layout: agent rules, architecture notes, a README, git, and (if you have GitHub CLI set up) a GitHub repo.

This repo (`quick-project-start`) is where that command is built and maintained. Running `./install.sh` copies it to `~/.local/bin/quick-proj` on your machine (and the supporting `lib/` modules next to it under `~/.local/share/quick-proj/`).

## Install and update

```bash
cd /path/to/quick-project-start
./install.sh
```

After pulling changes:

```bash
git pull
./install.sh
```

## Commands

| Command | What it does |
|---------|--------------|
| `quick-proj "my-app"` | Creates `~/Documents/coding-temp/my-app/` with scaffold files, git, and GitHub |
| `quick-proj --no-repo "my-app"` | Same but skips git and GitHub |
| `quick-proj --existing` | Adds scaffold files to the current directory |
| `quick-proj --update` | Refreshes agent rules and base skills, adds missing scaffold files, and renames a leftover `docs/` folder to `scaffold/` when needed |
| `quick-proj --agent-version` | Shows whether your project's scaffold rules are up to date |

## What a new project looks like

```
my-app/
  README.md
  .gitignore
  scripts/sz.py
  scaffold/
    AGENT-COMMS.md       # how agents should talk to you
    AGENT-WORKFLOW.md    # how agents should work
    ARCH-HUMAN.md        # architecture for humans (this kind of file)
    ARCH-LLM.md          # architecture for agents
    skills/              # base skills from quick-proj + any project-local skills
```

Root `AGENTS.md` points agents at `scaffold/` and says scaffold rules override everything else.

## This repo's layout

```
quick-project-start/
  quick-proj        # CLI entrypoint
  lib/              # modules the entrypoint loads
  install.sh        # installs quick-proj globally
  README.md         # usage for this repo
  templates/        # product source: agent rules + skills + blank project files
    skills/         # add a skill here once → ships to all new projects and --update
  scaffold/         # this project's own docs + agent-rule/skill copies (refreshed from templates/)
  tests/
```

When you change agent rules, edit only `templates/AGENT-COMMS.md` or `templates/AGENT-WORKFLOW.md`, bump the version line at the bottom of `templates/AGENT-WORKFLOW.md`, then run `./install.sh`. That installs the templates globally and refreshes this repo's `scaffold/AGENT-*.md` copies. Other projects pick up the new rules with `quick-proj --update`.

To ship a skill to every project: add `templates/skills/<skill-name>/SKILL.md`, bump the scaffold version, run `./install.sh`. New projects get it automatically; existing ones get it with `quick-proj --update`. Skills you add only inside one project's `scaffold/skills/` stay local and are not removed by `--update`.

## Configure defaults

Edit `~/.config/quick-proj/config.env`:

- `SCAFFOLD_DIR_NAME="scaffold"` — folder name for project docs (default). The old value `"docs"` is treated as `"scaffold"`.
- `BASE_DIR` — where new projects are created
- `TEMPLATES_DIR` — override template source

## Tests

```bash
./tests/run-tests.sh
```
