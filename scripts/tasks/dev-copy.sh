#!/usr/bin/env bash
# Copies a file, or the contents of a directory, into a directory of the running devcontainer, given as arguments or as SOURCE and DESTINATION.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Copies a file, or the contents of a directory, into a directory of the running devcontainer, given as arguments or as SOURCE and DESTINATION
function main() {
  copy "${1:-${SOURCE:-}}" "${2:-${DESTINATION:-}}"
}

main "$@"
