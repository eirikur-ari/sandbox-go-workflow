#!/usr/bin/env bash
# Checks the branch of the run for a workflow, by running the check-branch task with RELEASE_BRANCH set to the branch of GITHUB_REF.
# Requires GITHUB_REF in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../../../scripts/lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../../scripts/lib/env.sh"

# Prints the branch of the given ref, which is the ref itself when it is not a branch
function branchOf() {
  local ref="$1"

  echo "${ref#refs/heads/}"
}

# Runs the check-branch task for the branch of the run
function checkBranch() {
  requireEnv GITHUB_REF
  RELEASE_BRANCH="$(branchOf "$GITHUB_REF")" bash scripts/task.sh check-branch
}

# Checks the branch of the run
function main() {
  checkBranch
}

main
