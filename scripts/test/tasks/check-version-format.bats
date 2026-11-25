#!/usr/bin/env bats

load ../helpers

@test "fails with status 2 naming RELEASE_VERSION when it is empty" {
  RELEASE_VERSION="" run_script tasks/check-version-format.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_VERSION"* ]]
}

@test "accepts MAJOR.MINOR.PATCH" {
  local version
  for version in 0.0.0 1.2.3 10.20.30; do
    RELEASE_VERSION="$version" run_script tasks/check-version-format.sh
    [ "$status" -eq 0 ] || { echo "'$version' was rejected: $output"; return 1; }
  done
}

@test "rejects anything else" {
  local version
  for version in 1.2 v1.2.3 01.2.3 1.02.3 1.2.03 1.2.3-rc1 1.2.3.4 1.2.x " 1.2.3"; do
    RELEASE_VERSION="$version" run_script tasks/check-version-format.sh
    [ "$status" -eq 1 ] || { echo "'$version' was accepted"; return 1; }
    [[ "$output" == *"is not MAJOR.MINOR.PATCH"* ]]
  done
}
