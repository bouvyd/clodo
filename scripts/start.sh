#!/usr/bin/env bash
#
# Start the Odoo HTTP server (foreground) against a database.
# Browse it from the host at http://localhost:8069
#
# Usage:
#   ./scripts/start.sh [dbname] [extra odoo args]
#
# Env:
#   EXTRA_ADDONS_PATHS  comma-separated extra addon directories (see _common.sh)
set -euo pipefail
# shellcheck source=_common.sh
source "$(dirname "$0")/_common.sh"

DB="${1:-odoo}"; shift || true

setup_log "start" "${DB}"

odoo -d "${DB}" --dev=reload,qweb,xml "${ADDONS_PATH_ARG[@]}" "$@"
