#!/usr/bin/env bash
# Resolves the release version for a workflow, by running the resolve-version task.
# It writes the version and whether it is releasable to GITHUB_OUTPUT, and the reason to GITHUB_STEP_SUMMARY.
# Requires GITHUB_OUTPUT and GITHUB_STEP_SUMMARY in the environment, and REQUESTED_VERSION reaches the task when it is set.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../../../scripts/lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../../scripts/lib/env.sh"

# Prints the value of the given key in the given result lines
function valueOf() {
  local key="$1" result="$2"

  sed -n "s/^$key=//p" <<< "$result"
}

# Writes the version and whether it is releasable to the step output, and the reason to the step summary
function writeResult() {
  local result="$1" version releasable reason

  version=$(valueOf version "$result")
  releasable=$(valueOf releasable "$result")
  reason=$(valueOf reason "$result")
  {
    echo "version=$version"
    echo "releasable=$releasable"
  } >> "$GITHUB_OUTPUT"
  {
    echo "### Release validation"
    echo
    echo "- Version: ${version:-none}"
    echo "- Releasable: $releasable ($reason)"
  } >> "$GITHUB_STEP_SUMMARY"
}

# Runs the resolve-version task and writes its result for the workflow
function resolveVersion() {
  local result

  requireEnv GITHUB_OUTPUT GITHUB_STEP_SUMMARY
  result=$(bash scripts/task.sh resolve-version)
  writeResult "$result"
}

# Resolves the release version
function main() {
  resolveVersion
}

main
