#!/usr/bin/env bash
# Runs once, inside the container, right after it is created (mounts present).
set -euo pipefail

echo ">> Preparing Odoo dev container..."

# Data dir for filestore/sessions (bind-mounted to the host workspace).
mkdir -p /workspace/.odoo

# Sanity-check the mounted source repos.
for repo in odoo enterprise design-themes custom; do
  if [ ! -d "/workspace/src/${repo}" ] || [ -z "$(ls -A "/workspace/src/${repo}" 2>/dev/null)" ]; then
    echo "!! WARNING: /workspace/src/${repo} is empty — check the path in .env" >&2
  fi
done

# Install any Python requirements declared by the custom addons.
while IFS= read -r -d '' req; do
  echo ">> Installing custom requirements: ${req}"
  pip install -r "${req}" || echo "!! Failed to install ${req} (continuing)" >&2
done < <(find /workspace/src/custom -maxdepth 2 -name requirements.txt -print0 2>/dev/null)

echo ">> Odoo version: $(odoo --version 2>/dev/null || echo '??')"
echo ">> Done. Try:  ./scripts/run-tests.sh <module>"
