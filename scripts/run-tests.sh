#!/usr/bin/env bash
#
# Run a module's Odoo tests in a fresh, isolated database.
#
# Installs the module (and its dependencies), but by default runs ONLY the
# target module's tests (via --test-tags /<module>), not every dependency's.
#
# Usage:
#   ./scripts/run-tests.sh <module>[,<module>...] [extra odoo args]
#   ./scripts/run-tests.sh <module> --test-tags /custom_tag   # override scope
#   KEEP_DB=1 ./scripts/run-tests.sh <module>                 # keep DB to inspect
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

echo ">> (Re)creating test database '${DB}'"
dropdb --if-exists "${DB}"
createdb "${DB}"

echo ">> Installing '${MODULES}' and running tests ${EXTRA_TAGS[*]:-(all installed)}..."
set -x
odoo \
  -d "${DB}" \
  -i "${MODULES}" \
  --test-enable \
  --stop-after-init \
  --log-level=test \
  "${EXTRA_TAGS[@]}" \
  "${ADDONS_PATH_ARG[@]}" \
  "$@"
