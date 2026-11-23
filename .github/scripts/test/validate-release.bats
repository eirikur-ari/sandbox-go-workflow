#!/usr/bin/env bats

load helpers

@test "no argument exits 2 with the list of validations" {
  run_script
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be one of the following: branch, version-format, tag, release-notes, release"* ]]
}

@test "unknown argument exits 2" {
  run_script nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing or unknown argument"* ]]
}

@test "branch without GITHUB_REF exits 2 naming it" {
  unset GITHUB_REF
  run_script branch
  [ "$status" -eq 2 ]
  [[ "$output" == *"GITHUB_REF"* ]]
}

@test "version-format with an empty RELEASE_VERSION exits 2" {
  RELEASE_VERSION="" run_script version-format
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_VERSION"* ]]
}

@test "tag names every missing variable" {
  unset RELEASE_VERSION GITHUB_REPOSITORY GH_TOKEN
  run_script tag
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_VERSION GITHUB_REPOSITORY GH_TOKEN"* ]]
}

@test "release-notes without RELEASE_VERSION exits 2" {
  unset RELEASE_VERSION
  run_script release-notes
  [ "$status" -eq 2 ]
}

@test "release names every missing variable" {
  unset GITHUB_REF GITHUB_REPOSITORY GH_TOKEN
  run_script release
  [ "$status" -eq 2 ]
  [[ "$output" == *"GITHUB_REF GITHUB_REPOSITORY GH_TOKEN"* ]]
}

@test "branch accepts master" {
  on_branch master
  run_script branch
  [ "$status" -eq 0 ]
}

@test "branch accepts a release branch" {
  on_branch release/1.x
  run_script branch
  [ "$status" -eq 0 ]
}

@test "branch rejects any other branch and names it" {
  on_branch feature/x
  run_script branch
  [ "$status" -eq 1 ]
  [[ "$output" == *"feature/x"* ]]
}

@test "branch rejects a tag ref" {
  GITHUB_REF=refs/tags/v1.2.3 GITHUB_REF_NAME=v1.2.3 run_script branch
  [ "$status" -eq 1 ]
}

@test "version-format accepts MAJOR.MINOR.PATCH" {
  local version
  for version in 0.0.0 1.2.3 10.20.30; do
    RELEASE_VERSION="$version" run_script version-format
    [ "$status" -eq 0 ] || { echo "'$version' was rejected: $output"; return 1; }
  done
}

@test "version-format rejects anything else" {
  local version
  for version in 1.2 v1.2.3 01.2.3 1.02.3 1.2.03 1.2.3-rc1 1.2.3.4 1.2.x " 1.2.3"; do
    RELEASE_VERSION="$version" run_script version-format
    [ "$status" -eq 1 ] || { echo "'$version' was accepted"; return 1; }
    [[ "$output" == *"is not MAJOR.MINOR.PATCH"* ]]
  done
}

@test "tag passes when the tag does not exist" {
  GH_MODE=missing RELEASE_VERSION=1.2.3 GITHUB_REPOSITORY=owner/repo GH_TOKEN=t run_script tag
  [ "$status" -eq 0 ]
}

@test "tag fails when the tag exists" {
  GH_MODE=exists RELEASE_VERSION=1.2.3 GITHUB_REPOSITORY=owner/repo GH_TOKEN=t run_script tag
  [ "$status" -eq 1 ]
  [[ "$output" == *"tag v1.2.3 already exists"* ]]
}

@test "tag fails on a lookup error other than 404, and does not treat it as absent" {
  GH_MODE=error RELEASE_VERSION=1.2.3 GITHUB_REPOSITORY=owner/repo GH_TOKEN=t run_script tag
  [ "$status" -eq 1 ]
  [[ "$output" == *"HTTP 500"* ]]
  [[ "$output" != *"already exists"* ]]
}

@test "release-notes passes when make finds release notes" {
  RELEASE_VERSION=1.2.3 run_script release-notes
  [ "$status" -eq 0 ]
}

@test "release-notes fails when make finds none" {
  MAKE_FAIL=1 RELEASE_VERSION=1.2.3 run_script release-notes
  [ "$status" -ne 0 ]
}

@test "release rejects a branch that is not releasable from" {
  release_env
  on_branch feature/x
  run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "release fails when the changelog version cannot be read" {
  release_env
  CHANGELOG_VERSION_FAIL=1 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "release fails when the changelog version is not MAJOR.MINOR.PATCH" {
  release_env
  CHANGELOG_VERSION=1.2 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not MAJOR.MINOR.PATCH"* ]]
}

@test "release fails when the changelog has no release notes for the version" {
  release_env
  MAKE_FAIL=1 run_script release
  [ "$status" -ne 0 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "requested version that is not the latest in the changelog fails" {
  release_env
  REQUESTED_VERSION=1.2.2 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not the latest version in the changelog, '1.2.3'"* ]]
}

@test "requested version that is not MAJOR.MINOR.PATCH fails" {
  release_env
  REQUESTED_VERSION=v1.2.3 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not MAJOR.MINOR.PATCH"* ]]
}

@test "requested version whose tag exists fails" {
  release_env
  GH_MODE=exists REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"tag v1.2.3 already exists"* ]]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "requested version with unreleased entries fails" {
  release_env
  GH_MODE=missing CHANGELOG_UNRELEASED="- a change" REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unreleased section of the changelog has entries"* ]]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "requested version fails when the changelog has no Unreleased section" {
  release_env
  GH_MODE=missing CHANGELOG_UNRELEASED_FAIL=1 REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "requested version that is the latest, untagged and with no unreleased entries is releasable" {
  release_env
  GH_MODE=missing REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=1.2.3" "$GITHUB_OUTPUT"
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
  grep -q "Releasable: true (requested version)" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, an existing tag is not releasable" {
  release_env
  GH_MODE=exists run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=1.2.3" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "tag v1.2.3 already exists" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a failing tag lookup fails the run" {
  release_env
  GH_MODE=error run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "without a requested version, unreleased entries are not releasable" {
  release_env
  GH_MODE=missing CHANGELOG_UNRELEASED="- a change" run_script release
  [ "$status" -eq 0 ]
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "the Unreleased section of the changelog has entries" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a missing Unreleased section fails the run" {
  release_env
  GH_MODE=missing CHANGELOG_UNRELEASED_FAIL=1 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "without a requested version, the latest changelog version is releasable" {
  release_env
  GH_MODE=missing CHANGELOG_VERSION=2.0.0 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=2.0.0" "$GITHUB_OUTPUT"
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
  grep -q "Releasable: true (latest version of the changelog)" "$GITHUB_STEP_SUMMARY"
}
