#!/usr/bin/env bats

load ../helpers

@test "writes the version and whether it is releasable to the step output" {
  install_dispatchers
  FAKE_TASK_OUTPUT=$'version=1.2.3\nreleasable=true\nreason=requested version' run_script tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_OUTPUT")" = $'version=1.2.3\nreleasable=true' ]
  [ "$(cat "$TEST_TMP/calls.log")" = "core args=resolve-version cwd=$TEST_TMP/work" ]
}

@test "writes the version and the reason to the step summary" {
  install_dispatchers
  FAKE_TASK_OUTPUT=$'version=1.2.3\nreleasable=true\nreason=requested version' run_script tasks/resolve-version.sh
  grep -qx -e "- Version: 1.2.3" "$GITHUB_STEP_SUMMARY"
  grep -qx -e "- Releasable: true (requested version)" "$GITHUB_STEP_SUMMARY"
}

@test "writes an empty version and none to the summary when there is no version" {
  install_dispatchers
  FAKE_TASK_OUTPUT=$'version=\nreleasable=false\nreason=the changelog version 1.2.3 is not newer than the latest tag' run_script tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_OUTPUT")" = $'version=\nreleasable=false' ]
  grep -qx -e "- Version: none" "$GITHUB_STEP_SUMMARY"
  grep -qx -e "- Releasable: false (the changelog version 1.2.3 is not newer than the latest tag)" "$GITHUB_STEP_SUMMARY"
}

@test "passes REQUESTED_VERSION on to the task" {
  install_dispatchers
  FAKE_TASK_OUTPUT=$'version=1.2.3\nreleasable=true\nreason=requested version' REQUESTED_VERSION=1.2.3 run_script tasks/resolve-version.sh
  [ "$(cat "$TEST_TMP/env.log")" = "branch= requested=1.2.3" ]
}

@test "fails with status 2 naming the missing variables, without running the task" {
  install_dispatchers
  unset GITHUB_OUTPUT GITHUB_STEP_SUMMARY
  run_script tasks/resolve-version.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"GITHUB_OUTPUT GITHUB_STEP_SUMMARY"* ]]
  [ ! -e "$TEST_TMP/calls.log" ]
}

@test "fails with the status of the task and writes nothing" {
  install_dispatchers
  FAKE_SCRIPT_EXIT=1 run_script tasks/resolve-version.sh
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
  [ ! -s "$GITHUB_STEP_SUMMARY" ]
}
