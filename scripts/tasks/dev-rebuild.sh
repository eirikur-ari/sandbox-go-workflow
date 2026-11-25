#!/usr/bin/env bash
# Recreates the devcontainer from scratch without using the build cache.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Recreates the devcontainer from scratch without using the build cache
function main() {
  rebuild
}

main
