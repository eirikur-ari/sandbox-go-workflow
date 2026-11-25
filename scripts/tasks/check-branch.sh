#!/usr/bin/env bash
# Fails unless RELEASE_BRANCH is master or a release branch.
# Requires RELEASE_BRANCH in the environment, which is the name of the branch the release is started from.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

# Fails unless the release is started from master or a release branch
function verifyBranch() {
  requireEnv RELEASE_BRANCH
  if [[ "$RELEASE_BRANCH" != "master" && "$RELEASE_BRANCH" != release/* ]]; then
    echo "a release must be started from master or a release branch, not '$RELEASE_BRANCH'"
    exit 1
  fi
}

# Checks the branch the release is started from
function main() {
  verifyBranch
}

main
