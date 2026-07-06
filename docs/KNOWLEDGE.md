# Knowledge

Hard-won lessons for this tool. Agents working in quick-project-start may edit this file.

## new-proj templates must be refreshed by install.sh

After `git pull`, running `./install.sh` updates `~/.local/bin/new-proj` and copies the latest template files into `~/.config/new-proj/templates/`. New projects copy from that templates folder. If install only refreshed `bundled/AGENTS.md` but not `templates/`, `new-proj "foo"` would scaffold stale AGENTS.md even though `--update` looked current. Install now overwrites all managed templates on every run so `new-proj` and `install.sh` stay in sync.
