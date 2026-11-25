#!/usr/bin/env bash
# Stops the running devcontainer.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Stops the running devcontainer
function main() {
  stop
}

main
