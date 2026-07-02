# clodo — Odoo dev container

This repo is a containerized Odoo development environment. You (Claude) normally
run **inside** the `odoo` dev container, attached via VSCode Dev Containers.

## Layout (inside the container)
- `/workspace` — this repo (scripts, devcontainer config, `.mcp.json`)
- `/workspace/src/odoo` — Odoo community (rw mount, branch 19.0)
- `/workspace/src/enterprise` — Odoo enterprise (rw mount)
- `/workspace/src/design-themes` — design themes (rw mount)
- `/workspace/src/custom` — custom addons (rw mount)
- `/workspace/.odoo` — filestore/sessions (persisted on host)
- Python venv: `/opt/venv` (on PATH). `odoo` wrapper → `odoo-bin -c .devcontainer/odoo.conf`.

## Database
Postgres runs in the separate `db` service. From the container:
- CLI: `./scripts/dbsh.sh [dbname]` (or `psql -h db -U odoo ...`)
- MCP: the `postgres` server in `.mcp.json` is wired to `db:5432`.
- DO NOT USE THE `postgres` db for testing, etc. You can create new databases as you see fit. If you need to query and the MCP does not allow them, you can use the CLI.

## Running tests
```bash
./scripts/run-tests.sh <module>                 # fresh DB, install + run tests
./scripts/run-tests.sh <module> --test-tags /<module>
KEEP_DB=1 ./scripts/run-tests.sh <module>       # inspect the DB afterwards
```
A non-zero exit / `FAILED` lines in the log mean failing tests.

## Running the server
```bash
./scripts/init-db.sh mydb base       # one-time: create + install
./scripts/start.sh mydb              # serve on http://localhost:8069
```

## Notes
- Python is 3.12; dependency pins come from `src/odoo/requirements.txt`, baked
  into the image. If those change, run `bin/sync-requirements.sh` on the host and
  rebuild the container.
- The container user (`odoo`, uid 1000) matches the host user, so files you
  create in the mounted repos stay host-owned.
- The `odoo` config is provided via `ODOO_RC` (not `-c`) so subcommands like
  `odoo shell` work. Barcode/raster rendering deps (`rlPyCairo`) are installed.

## Known quirk
- `base`'s `TestCommand.test_shell` fails *under the test runner* (it spawns a
  server subprocess through a pty; flaky regardless of this setup). `odoo shell`
  itself works fine. It never runs when you scope tests to a real module, so
  ignore it — don't treat it as an environment problem.
