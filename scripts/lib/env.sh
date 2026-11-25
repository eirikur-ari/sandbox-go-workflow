# shellcheck shell=bash
# Functions to check the environment of a task.
# Sourced by the tasks, it sets no shell options and runs nothing.

# Fails with status 2 when a required environment variable is missing or empty
function requireEnv() {
  local missing=() name

  for name in "$@"; do
    [[ -n "${!name:-}" ]] || missing+=("$name")
  done
  if (( ${#missing[@]} > 0 )); then
    echo "missing or empty environment variables: ${missing[*]}" >&2
    exit 2
  fi
}
