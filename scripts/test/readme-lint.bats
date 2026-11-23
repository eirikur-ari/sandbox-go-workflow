#!/usr/bin/env bats

load helpers

# Writes a go.mod with the given go version
function write_go_mod() {
  printf 'module example.com/dummy\n\ngo %s\n' "$1" > "$WORKSPACE_FOLDER/go.mod"
}

# Writes a README.md with a Go version badge and a release badge of the given versions
function write_readme() {
  printf '![Go](https://img.shields.io/badge/Go-%s-blue)\n![Release](https://img.shields.io/badge/release-v%s-green)\n' "$1" "$2" > "$WORKSPACE_FOLDER/README.md"
}

@test "no argument exits 2 with the list of lints" {
  run_in_workspace readme-lint.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be one of the following: go-badge, release-badge"* ]]
}

@test "unknown argument exits 2" {
  run_in_workspace readme-lint.sh nope
  [ "$status" -eq 2 ]
}

@test "go-badge passes when the badge shows the go version of go.mod" {
  write_go_mod 1.26.10
  write_readme 1.26.10 1.2.3
  run_in_workspace readme-lint.sh go-badge
  [ "$status" -eq 0 ]
  [[ "$output" == *"Linting readme Go version badge"* ]]
}

@test "go-badge fails when the badge shows another go version" {
  write_go_mod 1.26.10
  write_readme 1.25.0 1.2.3
  run_in_workspace readme-lint.sh go-badge
  [ "$status" -eq 1 ]
  [[ "$output" == *"README.md Go version badge does not match go 1.26.10 in go.mod"* ]]
}

@test "go-badge does not accept a version that is only a prefix of the one in the badge" {
  write_go_mod 1.26.1
  write_readme 1.26.10 1.2.3
  run_in_workspace readme-lint.sh go-badge
  [ "$status" -eq 1 ]
}

@test "go-badge does not accept a badge with a version that is a prefix of go.mod" {
  write_go_mod 1.26.10
  write_readme 1.26.1 1.2.3
  run_in_workspace readme-lint.sh go-badge
  [ "$status" -eq 1 ]
}

@test "go-badge ignores a toolchain line of go.mod" {
  printf 'module example.com/dummy\n\ngo 1.26.10\n\ntoolchain go1.26.11\n' > "$WORKSPACE_FOLDER/go.mod"
  write_readme 1.26.10 1.2.3
  run_in_workspace readme-lint.sh go-badge
  [ "$status" -eq 0 ]
}

@test "release-badge passes when the badge shows RELEASE_VERSION" {
  write_readme 1.26.10 1.2.3
  RELEASE_VERSION=1.2.3 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 0 ]
  [[ "$output" == *"Linting readme release badge"* ]]
}

@test "release-badge fails when the badge shows another version than RELEASE_VERSION" {
  write_readme 1.26.10 1.2.2
  RELEASE_VERSION=1.2.3 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 1 ]
  [[ "$output" == *"README.md release badge does not show any of: 1.2.3"* ]]
}

@test "release-badge with RELEASE_VERSION does not look at the tags or the changelog" {
  write_readme 1.26.10 1.2.3
  RELEASE_VERSION=1.2.3 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_TMP/git.log" ]
}

@test "release-badge without RELEASE_VERSION accepts the version of the latest tag" {
  write_standard_changelog
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.2
  GIT_TAG=v1.2.2 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION accepts the version of the latest changelog release" {
  write_standard_changelog
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.3
  GIT_TAG=v1.2.2 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION fails when the badge shows neither and lists both" {
  write_standard_changelog
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.1
  GIT_TAG=v1.2.2 run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not show any of: 1.2.2 1.2.3"* ]]
}

@test "release-badge without RELEASE_VERSION asks git for the latest v tag" {
  write_standard_changelog
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.3
  GIT_TAG=v1.2.2 run_in_workspace readme-lint.sh release-badge
  grep -qx "git describe --tags --abbrev=0 --match v\*" "$TEST_TMP/git.log"
}

@test "release-badge without RELEASE_VERSION falls back to the changelog when there is no tag" {
  write_standard_changelog
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.3
  run_in_workspace readme-lint.sh release-badge
  [ "$status" -eq 0 ]
}

@test "release-badge without RELEASE_VERSION fails when there is no tag and no release in the changelog" {
  printf '## [Unreleased]\n' > "$WORKSPACE_FOLDER/CHANGELOG.md"
  install_script changelog-version.sh
  write_readme 1.26.10 1.2.3
  run_in_workspace readme-lint.sh release-badge
  [ "$status" -ne 0 ]
  [[ "$output" == *"no release found in the changelog"* ]]
}
