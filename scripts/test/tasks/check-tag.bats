#!/usr/bin/env bats

load ../helpers

@test "fails with status 2 naming RELEASE_VERSION when it is missing" {
  unset RELEASE_VERSION
  run_script tasks/check-tag.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_VERSION"* ]]
}

@test "passes when the tag does not exist" {
  GIT_TAGS=v1.2.2 RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  [ "$status" -eq 0 ]
}

@test "passes when there are no tags" {
  RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  [ "$status" -eq 0 ]
}

@test "fails when the tag exists" {
  GIT_TAGS=$'v1.2.3\nv1.2.2' RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"tag v1.2.3 already exists"* ]]
}

@test "does not mistake a tag that only starts like the release tag for it" {
  GIT_TAGS=v1.2.30 RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  [ "$status" -eq 0 ]
}

@test "looks the tag up in git" {
  GIT_TAGS=v1.2.2 RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  grep -qx "git show-ref --verify --quiet refs/tags/v1.2.3" "$TEST_TMP/git.log"
}

@test "fails on a git error, and does not treat it as an absent tag" {
  GIT_FAIL=1 RELEASE_VERSION=1.2.3 run_script tasks/check-tag.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not look up the tag v1.2.3"* ]]
  [[ "$output" != *"already exists"* ]]
}
