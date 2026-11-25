#!/usr/bin/env bats

load ../helpers

# Writes a go.mod with the given go version
function write_go_mod() {
  printf 'module example.com/dummy\n\ngo %s\n' "$1" > "$WORKSPACE_FOLDER/go.mod"
}

# Writes a README.md with a Go version badge and a release badge of the given versions
function write_readme() {
  printf '![Go](https://img.shields.io/badge/Go-%s-blue)\n![Release](https://img.shields.io/badge/release-v%s-green)\n' "$1" "$2" > "$WORKSPACE_FOLDER/README.md"
}

@test "go-badge passes when the badge shows the go version of go.mod" {
  write_go_mod 1.26.10
  write_readme 1.26.10 1.2.3
  run_in_workspace tasks/readme-lint-go-badge.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Linting readme Go version badge"* ]]
}

@test "go-badge fails when the badge shows another go version" {
  write_go_mod 1.26.10
  write_readme 1.25.0 1.2.3
  run_in_workspace tasks/readme-lint-go-badge.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"README.md Go version badge does not match go 1.26.10 in go.mod"* ]]
}

@test "go-badge does not accept a version that is only a prefix of the one in the badge" {
  write_go_mod 1.26.1
  write_readme 1.26.10 1.2.3
  run_in_workspace tasks/readme-lint-go-badge.sh
  [ "$status" -eq 1 ]
}

@test "go-badge does not accept a badge with a version that is a prefix of go.mod" {
  write_go_mod 1.26.10
  write_readme 1.26.1 1.2.3
  run_in_workspace tasks/readme-lint-go-badge.sh
  [ "$status" -eq 1 ]
}

@test "go-badge ignores a toolchain line of go.mod" {
  printf 'module example.com/dummy\n\ngo 1.26.10\n\ntoolchain go1.26.11\n' > "$WORKSPACE_FOLDER/go.mod"
  write_readme 1.26.10 1.2.3
  run_in_workspace tasks/readme-lint-go-badge.sh
  [ "$status" -eq 0 ]
}
