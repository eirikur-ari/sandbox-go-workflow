#!/usr/bin/env bash
# Starts the devcontainer of this workspace, building it when needed.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Starts the devcontainer of this workspace, building it when needed
function main() {
  start
}

main
