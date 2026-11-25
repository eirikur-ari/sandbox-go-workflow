#!/usr/bin/env bash
# Removes the devcontainer and the image it was built from.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Removes the devcontainer and the image it was built from
function main() {
  destroy
}

main
