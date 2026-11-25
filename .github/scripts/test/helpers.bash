# shellcheck shell=bash
# Shared setup for the bats tests of the scripts in .github/scripts/.
# Each test runs in a temp working directory, which stands for the root of the repository, with GITHUB_OUTPUT and GITHUB_STEP_SUMMARY set to files of the test.
# install_dispatchers puts a fake task dispatcher of scripts in the working directory, driven by environment variables set per test:
#   FAKE_TASK_OUTPUT         what the fake dispatcher prints, default nothing
#   FAKE_SCRIPT_EXIT         the exit status of the fake dispatcher, default 0
# The fake logs every call to calls.log in TEST_TMP as "core args=<arguments> cwd=<directory>",
# and the variables it was given to env.log as "branch=<RELEASE_BRANCH> requested=<REQUESTED_VERSION>".

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Creates the temp working directory before each test
function setup() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
  mkdir -p "$TEST_TMP/work"
  export GITHUB_OUTPUT="$TEST_TMP/output"
  export GITHUB_STEP_SUMMARY="$TEST_TMP/summary"
  : > "$GITHUB_OUTPUT"
  : > "$GITHUB_STEP_SUMMARY"

  cd "$TEST_TMP/work" || return 1
}

# Removes the temp working directory after each test
function teardown() {
  rm -rf "$TEST_TMP"
}

# Runs the given script of .github/scripts with the given arguments, capturing status and output (stdout and stderr) in bats' $status and $output
function run_script() {
  local script="$1"
  shift
  run bash "$SCRIPTS/$script" "$@"
}

# Copies the GitHub task dispatcher into the working directory, next to a fake task dispatcher of scripts that logs its call, and an empty adapters directory
function install_dispatchers() {
  mkdir -p "$TEST_TMP/work/.github/scripts/tasks" "$TEST_TMP/work/scripts"
  cp "$SCRIPTS/task.sh" "$TEST_TMP/work/.github/scripts/task.sh"
  cat > "$TEST_TMP/work/scripts/task.sh" <<'EOF2'
#!/usr/bin/env bash
echo "core args=$* cwd=$PWD" >> "$TEST_TMP/calls.log"
echo "branch=${RELEASE_BRANCH:-} requested=${REQUESTED_VERSION:-}" >> "$TEST_TMP/env.log"
[[ -z "${FAKE_TASK_OUTPUT:-}" ]] || printf '%s\n' "$FAKE_TASK_OUTPUT"
exit "${FAKE_SCRIPT_EXIT:-0}"
EOF2
}

# Adds a GitHub adapter to the working directory for the given task, with the given commands
function add_adapter() {
  local name="$1" commands="$2"

  printf '#!/usr/bin/env bash\n%s\n' "$commands" > "$TEST_TMP/work/.github/scripts/tasks/$name.sh"
}

# Runs the GitHub task dispatcher of the working directory with the given arguments, capturing status and output (stdout and stderr) in bats' $status and $output
function run_task() {
  run bash "$TEST_TMP/work/.github/scripts/task.sh" "$@"
}
