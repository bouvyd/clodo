#!/usr/bin/env bash
#
# Run on the HOST. Re-copies Odoo's requirements.txt into the build context so a
# `Rebuild Container` picks up dependency changes. Reads ODOO_SRC from .env.
set -euo pipefail
cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
set -a; . ./.devcontainer/.env; set +a

src="${ODOO_SRC:?ODOO_SRC not set in .env}/requirements.txt"
cp "${src}" .devcontainer/requirements.odoo.txt
echo ">> Synced ${src} -> .devcontainer/requirements.odoo.txt"
echo ">> Now run 'Dev Containers: Rebuild Container' in VSCode."
