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

@test "requested version fails when the changelog version cannot be read" {
  release_env
  CHANGELOG_VERSION_FAIL=1 REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "requested version does not look at the git tags" {
  release_env
  GH_MODE=missing GIT_SHALLOW=true GIT_FAIL=1 REQUESTED_VERSION=1.2.3 run_script release
  [ "$status" -eq 0 ]
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
}

@test "without a requested version, a newer changelog version that is not MAJOR.MINOR.PATCH fails" {
  release_env
  CHANGELOG_VERSION=1.2 run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not MAJOR.MINOR.PATCH"* ]]
}

@test "without a requested version, a newer changelog version with no release notes fails" {
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

@test "without a requested version, a changelog version newer than the latest tag is releasable" {
  release_env
  GH_MODE=missing GIT_TAGS=v1.2.2 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=1.2.3" "$GITHUB_OUTPUT"
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
  grep -q "Releasable: true (the changelog version is newer than the latest tag)" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a changelog version is releasable when there is no tag" {
  release_env
  GH_MODE=missing CHANGELOG_VERSION=1.0.0 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=1.0.0" "$GITHUB_OUTPUT"
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
}

@test "without a requested version, a changelog version equal to the latest tag gives no version" {
  release_env
  GIT_TAGS=v1.2.3 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "the changelog version 1.2.3 is not newer than the latest tag" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a changelog version older than the latest tag gives no version" {
  release_env
  GIT_TAGS=$'v1.2.0\nv1.3.0' run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
}

@test "without a requested version, versions are compared by number, not as text" {
  release_env
  GH_MODE=missing GIT_TAGS=$'v1.9.0\nv1.10.0' CHANGELOG_VERSION=1.9.5 run_script release
  [ "$status" -eq 0 ]
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  : > "$GITHUB_OUTPUT"
  GH_MODE=missing GIT_TAGS=$'v1.9.0\nv1.10.0' CHANGELOG_VERSION=1.10.1 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=1.10.1" "$GITHUB_OUTPUT"
  grep -qx "releasable=true" "$GITHUB_OUTPUT"
}

@test "without a requested version, a version that is not newer skips every validation" {
  release_env
  GH_MODE=error MAKE_FAIL=1 CHANGELOG_UNRELEASED_FAIL=1 GIT_TAGS=v1.2.3 run_script release
  [ "$status" -eq 0 ]
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
}

@test "without a requested version, a changelog without a release gives no version" {
  release_env
  CHANGELOG_VERSION_FAIL=1 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "no release version found in the changelog" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a newer version whose tag exists gives no version" {
  release_env
  GH_MODE=exists GIT_TAGS=v1.2.2 run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "tag v1.2.3 already exists" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a failing tag lookup fails the run" {
  release_env
  GH_MODE=error GIT_TAGS=v1.2.2 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "without a requested version, a newer version with unreleased entries gives no version" {
  release_env
  GH_MODE=missing GIT_TAGS=v1.2.2 CHANGELOG_UNRELEASED="- a change" run_script release
  [ "$status" -eq 0 ]
  grep -qx "version=" "$GITHUB_OUTPUT"
  grep -qx "releasable=false" "$GITHUB_OUTPUT"
  grep -q "the Unreleased section of the changelog has entries" "$GITHUB_STEP_SUMMARY"
}

@test "without a requested version, a newer version fails when the changelog has no Unreleased section" {
  release_env
  GH_MODE=missing GIT_TAGS=v1.2.2 CHANGELOG_UNRELEASED_FAIL=1 run_script release
  [ "$status" -eq 1 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "without a requested version, a shallow repository fails the run" {
  release_env
  GIT_SHALLOW=true run_script release
  [ "$status" -eq 1 ]
  [[ "$output" == *"the repository is shallow"* ]]
  [ ! -s "$GITHUB_OUTPUT" ]
}

@test "without a requested version, a failing git fails the run" {
  release_env
  GIT_FAIL=1 run_script release
  [ "$status" -ne 0 ]
  [ ! -s "$GITHUB_OUTPUT" ]
}
