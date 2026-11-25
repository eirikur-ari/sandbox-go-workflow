#!/usr/bin/env bats

load ../helpers

@test "runs the check-branch task with the branch of GITHUB_REF" {
  install_dispatchers
  GITHUB_REF=refs/heads/release/1.x run_script tasks/check-branch.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/calls.log")" = "core args=check-branch cwd=$TEST_TMP/work" ]
  [ "$(cat "$TEST_TMP/env.log")" = "branch=release/1.x requested=" ]
}

@test "gives master as the branch of the master ref" {
  install_dispatchers
  GITHUB_REF=refs/heads/master run_script tasks/check-branch.sh
  [ "$(cat "$TEST_TMP/env.log")" = "branch=master requested=" ]
}

@test "leaves a ref that is not a branch as it is, for the task to reject" {
  install_dispatchers
  GITHUB_REF=refs/tags/v1.2.3 run_script tasks/check-branch.sh
  [ "$(cat "$TEST_TMP/env.log")" = "branch=refs/tags/v1.2.3 requested=" ]
}

@test "fails with status 2 naming GITHUB_REF when it is missing, without running the task" {
  install_dispatchers
  unset GITHUB_REF
  run_script tasks/check-branch.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"GITHUB_REF"* ]]
  [ ! -e "$TEST_TMP/calls.log" ]
}

@test "fails with the status of the task" {
  install_dispatchers
  GITHUB_REF=refs/heads/feature/x FAKE_SCRIPT_EXIT=1 run_script tasks/check-branch.sh
  [ "$status" -eq 1 ]
}
