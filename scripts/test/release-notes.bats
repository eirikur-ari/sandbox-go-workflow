#!/usr/bin/env bats

load helpers

@test "fails when RELEASE_VERSION is not set" {
  write_standard_changelog
  run_in_workspace release-notes.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"release version is missing or empty"* ]]
}

@test "fails when RELEASE_VERSION is empty" {
  write_standard_changelog
  RELEASE_VERSION="" run_in_workspace release-notes.sh
  [ "$status" -eq 2 ]
}

@test "prints the section of a release without its heading or surrounding blank lines" {
  write_standard_changelog
  RELEASE_VERSION=1.2.3 run_in_workspace release-notes.sh
  [ "$status" -eq 0 ]
  [ "$output" = $'### Fixed\n\n- Fix three' ]
}

@test "stops at the next release" {
  write_standard_changelog
  RELEASE_VERSION=1.2.3 run_in_workspace release-notes.sh
  [[ "$output" != *"Add two"* ]]
  [[ "$output" != *"Unreleased entry"* ]]
}

@test "stops at the link references when the release is the last section" {
  write_standard_changelog
  RELEASE_VERSION=1.2.2 run_in_workspace release-notes.sh
  [ "$status" -eq 0 ]
  [ "$output" = $'### Added\n\n- Add two' ]
}

@test "prints the first section of the changelog" {
  write_changelog <<'EOF'
## [2.0.0] - 2026-03-01

- Major change

## [1.0.0] - 2026-01-01

- First release
EOF
  RELEASE_VERSION=2.0.0 run_in_workspace release-notes.sh
  [ "$status" -eq 0 ]
  [ "$output" = "- Major change" ]
}

@test "does not match a version that only starts like the requested one" {
  write_standard_changelog
  RELEASE_VERSION=1.2 run_in_workspace release-notes.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHANGELOG.md has no entries for 1.2"* ]]
}

@test "treats the dots of the version literally" {
  write_changelog <<'EOF'
## [1x2x3] - 2026-01-02

- Not a match
EOF
  RELEASE_VERSION=1.2.3 run_in_workspace release-notes.sh
  [ "$status" -eq 1 ]
}

@test "fails when the changelog has no section for the version" {
  write_standard_changelog
  RELEASE_VERSION=9.9.9 run_in_workspace release-notes.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHANGELOG.md has no entries for 9.9.9"* ]]
}

@test "fails when the section of the version is empty" {
  write_changelog <<'EOF'
## [1.2.3] - 2026-01-02

## [1.2.2] - 2026-01-01

- Add two
EOF
  RELEASE_VERSION=1.2.3 run_in_workspace release-notes.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHANGELOG.md has no entries for 1.2.3"* ]]
}

@test "fails when there is no changelog" {
  RELEASE_VERSION=1.2.3 run_in_workspace release-notes.sh
  [ "$status" -ne 0 ]
}
