#!/usr/bin/env bash
#
# Create a database and install one or more modules into it (no tests).
# Handy for a dev DB you then run the server against.
#
# Usage:
#   ./scripts/init-db.sh <dbname> [module,module]   # default modules: base
#
# Env:
#   EXTRA_ADDONS_PATHS  comma-separated extra addon directories (see _common.sh)
set -euo pipefail
# shellcheck source=_common.sh
source "$(dirname "$0")/_common.sh"

DB="${1:-odoo}"
MODULES="${2:-base}"

setup_log "init-db" "${DB}"
echo ">> Creating database '${DB}' (if needed) and installing '${MODULES}'"
createdb "${DB}" 2>/dev/null || echo ">> database '${DB}' already exists"

odoo -d "${DB}" -i "${MODULES}" --stop-after-init --without-demo=False \
  "${ADDONS_PATH_ARG[@]}"
echo ">> Done. Start the server with:  ./scripts/start.sh ${DB}"
