# clodo

A self-contained, Docker-based Odoo development & test environment, designed so
an agent (Claude Code) can build, run and test Odoo unattended. Starts with
Odoo **19.0**; the layout is parametrized for other versions.

## What you get
- A **`odoo`** dev container (Python 3.12, Debian 12, wkhtmltopdf, all Odoo deps)
  that you attach to from VSCode (**Dev Containers: Reopen in Container**).
- A separate **`db`** Postgres container, networked to it.
- Your existing repos mounted **read-write**: `odoo`, `enterprise`,
  `design-themes`, and custom addons.
- Helper scripts to init DBs, run a server, and run module tests headless.
- A Postgres **MCP** server so Claude can query the DB; plus `psql` on the CLI.

## One-time setup
1. Install Docker + the VSCode **Dev Containers** extension.
2. Copy and edit env (lives next to the compose file):
   ```bash
   cp .devcontainer/.env.example .devcontainer/.env   # (already filled in for this machine)
   ```
   Set `USER_UID`/`USER_GID` (`id -u`, `id -g`) and the four repo paths.
3. Vendor Odoo's dependency list into the build context:
   ```bash
   ./bin/sync-requirements.sh
   ```
4. In VSCode: open this folder → **Dev Containers: Reopen in Container**.
   First build compiles Python deps (a few minutes), then `post-create.sh` runs.

## Daily use (inside the container)
```bash
./scripts/run-tests.sh <module>      # create fresh DB, install module, run tests
./scripts/init-db.sh mydb base       # create a dev DB
./scripts/start.sh mydb              # http://localhost:8069
./scripts/dbsh.sh mydb               # psql shell
```

## Multiple Odoo versions
Duplicate this checkout (or use a second `.env`) with a different
`COMPOSE_PROJECT_NAME`, `ODOO_VERSION`, repo paths, and host ports
(`ODOO_HTTP_PORT`, `DB_PORT`, ...). The Dockerfile/compose are version-agnostic;
only `.env` changes.

See [CLAUDE.md](CLAUDE.md) for the in-container reference.
