#!/usr/bin/env bash
# Runs a task of scripts/tasks by name from the workspace, passing on the arguments that follow the name.
# A task is a file of scripts/tasks that is named after the task and describes itself on its second line.
# list prints the tasks with their descriptions, or only their names when it is given --names, and help prints the description of one task.
# WORKSPACE_FOLDER defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

TASKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tasks"

# Prints the names of the tasks, one per line
function taskNames() {
  local file

  for file in "$TASKS_DIR"/*.sh; do
    [[ -e "$file" ]] || return 0
    basename "$file" .sh
  done
}

# Prints the description of the given task, which is the second line of its file without the comment mark
function taskDescription() {
  local name="$1"

  sed -n '2s/^# *//p' "$TASKS_DIR/$name.sh"
}

# Prints every task with its description, or only the names of the tasks when the argument is --names
function listTasks() {
  local mode="${1:-}" name

  while IFS= read -r name; do
    if [[ "$mode" == "--names" ]]; then
      echo "$name"
    else
      printf '%-26s %s\n' "$name" "$(taskDescription "$name")"
    fi
  done < <(taskNames)
}

# Fails unless the given name is the name of a task
function requireTask() {
  local name="$1"

  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ || ! -f "$TASKS_DIR/$name.sh" ]]; then
    echo "unknown task '$name', the tasks are:" >&2
    listTasks >&2
    exit 2
  fi
}

# Prints how to use the dispatcher, followed by the tasks
function usage() {
  echo "Usage: task.sh <task> [arguments]"
  echo
  listTasks
}

# Prints the description of the given task, or how to use the dispatcher when there is no task
function helpTask() {
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    usage
    return
  fi
  requireTask "$name"
  taskDescription "$name"
}

# Runs the given task from the workspace with the given arguments
function runTask() {
  local name="$1"
  shift

  requireTask "$name"
  cd "$WORKSPACE_FOLDER"
  bash "$TASKS_DIR/$name.sh" "$@"
}

# Runs the requested task, or lists the tasks
function main() {
  case "${1:-}" in
    "")
      usage >&2
      exit 2
      ;;
    list) listTasks "${2:-}" ;;
    help) helpTask "${2:-}" ;;
    *) runTask "$@" ;;
  esac
}

main "$@"
