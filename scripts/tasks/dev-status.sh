#!/usr/bin/env bash
# Shows the id, status and image of the devcontainer.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Shows the id, status and image of the devcontainer
function main() {
  status
}

main
