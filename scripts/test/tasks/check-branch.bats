#!/usr/bin/env bats

load ../helpers

@test "fails with status 2 naming RELEASE_BRANCH when it is missing" {
  unset RELEASE_BRANCH
  run_script tasks/check-branch.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_BRANCH"* ]]
}

@test "accepts master" {
  RELEASE_BRANCH=master run_script tasks/check-branch.sh
  [ "$status" -eq 0 ]
}

@test "accepts a release branch" {
  RELEASE_BRANCH=release/1.x run_script tasks/check-branch.sh
  [ "$status" -eq 0 ]
}

@test "rejects any other branch and names it" {
  RELEASE_BRANCH=feature/x run_script tasks/check-branch.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"not 'feature/x'"* ]]
}

@test "rejects a branch that only starts like master or a release branch" {
  local branch
  for branch in master-copy releases/1.x release mastery; do
    RELEASE_BRANCH="$branch" run_script tasks/check-branch.sh
    [ "$status" -eq 1 ] || { echo "'$branch' was accepted"; return 1; }
  done
}

@test "rejects a tag ref" {
  RELEASE_BRANCH=refs/tags/v1.2.3 run_script tasks/check-branch.sh
  [ "$status" -eq 1 ]
}
