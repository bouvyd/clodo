#!/usr/bin/env bash
#
# Open a psql shell against the `db` service (or run a query).
#
# Usage:
#   ./scripts/dbsh.sh [dbname]              # interactive psql
#   ./scripts/dbsh.sh <dbname> -c "SELECT 1"
set -euo pipefail

DB="${1:-postgres}"; shift || true
exec psql -h db -U "${PGUSER:-odoo}" -d "${DB}" "$@"
