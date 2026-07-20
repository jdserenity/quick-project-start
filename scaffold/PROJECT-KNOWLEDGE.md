# Project knowledge

Hard-won lessons for this tool. Agents working in quick-project-start may edit this file.

## quick-proj templates must be refreshed by install.sh

After `git pull`, running `./install.sh` updates `~/.local/bin/quick-proj` and copies the latest template files into `~/.config/quick-proj/templates/`. New projects copy from that templates folder. If install only refreshed bundled agent files but not `templates/`, `quick-proj "foo"` would scaffold stale rules even though `--update` looked current. Install now overwrites all managed templates on every run so `quick-proj` and `install.sh` stay in sync.

## Renamed from new-proj

`install.sh` migrates `~/.config/new-proj` → `~/.config/quick-proj`, removes `~/.local/bin/new-proj`, and upgrades `~/.zshrc` shell-integration lines when present. Per-run env vars are `QUICK_PROJ_*`; `NEW_PROJ_*` still works for older scripts.
