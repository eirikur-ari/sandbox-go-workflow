#!/usr/bin/env bats

load ../helpers

# Writes a README.md with a Go version badge and a release badge of the given versions
function write_readme() {
  printf '![Go](https://img.shields.io/badge/Go-%s-blue)\n![Release](https://img.shields.io/badge/release-v%s-green)\n' "$1" "$2" > "$WORKSPACE_FOLDER/README.md"
}

@test "release-badge passes when the badge shows RELEASE_VERSION" {
  write_readme 1.26.10 1.2.3
  RELEASE_VERSION=1.2.3 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Linting readme release badge"* ]]
}

@test "release-badge fails when the badge shows another version than RELEASE_VERSION" {
  write_readme 1.26.10 1.2.2
  RELEASE_VERSION=1.2.3 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"README.md release badge does not show any of: 1.2.3"* ]]
}

@test "release-badge with RELEASE_VERSION does not look at the tags or the changelog" {
  write_readme 1.26.10 1.2.3
  RELEASE_VERSION=1.2.3 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_TMP/git.log" ]
}

@test "release-badge without RELEASE_VERSION accepts the version of the latest tag" {
  write_standard_changelog
  install_task changelog-version
  write_readme 1.26.10 1.2.2
  GIT_TAG=v1.2.2 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION accepts the version of the latest changelog release" {
  write_standard_changelog
  install_task changelog-version
  write_readme 1.26.10 1.2.3
  GIT_TAG=v1.2.2 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION fails when the badge shows neither and lists both" {
  write_standard_changelog
  install_task changelog-version
  write_readme 1.26.10 1.2.1
  GIT_TAG=v1.2.2 run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not show any of: 1.2.2 1.2.3"* ]]
}

@test "release-badge without RELEASE_VERSION asks git for the latest v tag" {
  write_standard_changelog
  install_task changelog-version
  write_readme 1.26.10 1.2.3
  GIT_TAG=v1.2.2 run_in_workspace tasks/readme-lint-release-badge.sh
  grep -qx "git describe --tags --abbrev=0 --match v\*" "$TEST_TMP/git.log"
}

@test "release-badge without RELEASE_VERSION falls back to the changelog when there is no tag" {
  write_standard_changelog
  install_task changelog-version
  write_readme 1.26.10 1.2.3
  run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION fails when there is no tag and no release in the changelog" {
  printf '## [Unreleased]\n' > "$WORKSPACE_FOLDER/CHANGELOG.md"
  install_task changelog-version
  write_readme 1.26.10 1.2.3
  run_in_workspace tasks/readme-lint-release-badge.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"no release found in the changelog"* ]]
}
