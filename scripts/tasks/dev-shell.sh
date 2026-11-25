#!/usr/bin/env bash
# Opens a shell in the devcontainer, DC_SHELL selects the shell and defaults to zsh.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/devcontainer.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/devcontainer.sh"

# Opens a shell in the devcontainer, DC_SHELL selects the shell and defaults to zsh
function main() {
  shell
}

main
