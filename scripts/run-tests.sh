#!/usr/bin/env bash
#
# Run a module's Odoo tests in a database.
#
# Installs the module (and its dependencies), but by default runs ONLY the
# target module's tests (via --test-tags /<module>), not every dependency's.
#
# If TEST_DB names a database that already exists, it is reused as-is: no
# drop/create, no -i/-u, just a plain boot + --test-tags run against whatever
# is already installed there. This is much faster for iterating on the same
# set of tests, but means module code/data changes won't be picked up until
# you drop the DB (or upgrade it yourself) — Odoo only re-runs a module's
# tests during install/upgrade of that module.
#
# Usage:
#   ./scripts/run-tests.sh <module>[,<module>...] [extra odoo args]
#   ./scripts/run-tests.sh <module> --test-tags /custom_tag   # override scope
#   KEEP_DB=1 ./scripts/run-tests.sh <module>                 # keep DB to inspect
#   TEST_DB=mydb ./scripts/run-tests.sh <module>              # name/reuse a DB
#
# Env:
#   EXTRA_ADDONS_PATHS  comma-separated extra addon directories (see _common.sh)
set -euo pipefail
# shellcheck source=_common.sh
source "$(dirname "$0")/_common.sh"

if [ $# -lt 1 ]; then
  echo "usage: $0 <module>[,<module>...] [extra odoo args]" >&2
  exit 2
fi

MODULES="$1"; shift
DB="${TEST_DB:-test_${MODULES%%,*}}"

setup_log "run-tests" "${DB}"

# Scope tests to the requested module(s) unless the caller passed --test-tags.
EXTRA_TAGS=()
if [[ " $* " != *" --test-tags "* ]]; then
  tags=""
  IFS=',' read -ra _mods <<< "${MODULES}"
  for m in "${_mods[@]}"; do tags+="${tags:+,}/${m}"; done
  EXTRA_TAGS=(--test-tags "${tags}")
fi

cleanup() {
  if [ -z "${KEEP_DB:-}" ]; then
    echo ">> Dropping test database '${DB}'"
    dropdb --if-exists "${DB}" || true
  else
    echo ">> Keeping test database '${DB}' (KEEP_DB set)"
  fi
}
trap cleanup EXIT

INSTALL_ARGS=(-i "${MODULES}")
if psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB}'" | grep -q 1; then
  echo ">> Reusing existing test database '${DB}' (no install/update, just running tests)"
  INSTALL_ARGS=()
else
  echo ">> Creating test database '${DB}'"
  createdb "${DB}"
fi

echo ">> Running tests ${EXTRA_TAGS[*]:-(all installed)} on '${DB}'..."
set -x
odoo \
  -d "${DB}" \
  "${INSTALL_ARGS[@]}" \
  --test-enable \
  --stop-after-init \
  --log-level=test \
  "${EXTRA_TAGS[@]}" \
  "${ADDONS_PATH_ARG[@]}" \
  "$@"
