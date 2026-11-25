#!/usr/bin/env bash
# Runs a task for a workflow: the GitHub adapter of the task in .github/scripts/tasks when there is one, and otherwise the task of scripts/tasks.
# The adapter runs from the root of the repository. list, help and everything else go to the task dispatcher of scripts/task.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Succeeds when the given task has a GitHub adapter
function hasAdapter() {
  local name="$1"

  [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ && -f "$ROOT/.github/scripts/tasks/$name.sh" ]]
}

# Runs the GitHub adapter of the given task from the root of the repository, with the given arguments
function runAdapter() {
  local name="$1"
  shift

  cd "$ROOT"
  bash ".github/scripts/tasks/$name.sh" "$@"
}

# Runs the task dispatcher of scripts with the given arguments
function runCoreTask() {
  bash "$ROOT/scripts/task.sh" "$@"
}

# Runs the requested task through its adapter when it has one
function main() {
  if hasAdapter "${1:-}"; then
    runAdapter "$@"
  else
    runCoreTask "$@"
  fi
}

main "$@"
