#!/usr/bin/env bats

load ../helpers

@test "prints the version of the latest release, skipping the Unreleased section" {
  write_standard_changelog
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "1.2.3" ]
}

@test "prints a version with a pre-release suffix as written" {
  write_changelog <<'EOF'
## [Unreleased]

## [1.3.0-rc.1] - 2026-02-01

## [1.2.3] - 2026-01-02
EOF
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "1.3.0-rc.1" ]
}

@test "prints the first release when the changelog has no Unreleased section" {
  write_changelog <<'EOF'
## [2.0.0] - 2026-03-01

## [1.9.9] - 2026-02-01
EOF
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "2.0.0" ]
}

@test "fails when the changelog has only an Unreleased section" {
  write_changelog <<'EOF'
## [Unreleased]

- Something
EOF
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"no release found in the changelog"* ]]
}

@test "fails when the changelog is empty" {
  : > "$WORKSPACE_FOLDER/CHANGELOG.md"
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"no release found in the changelog"* ]]
}

@test "fails when there is no changelog" {
  run_in_workspace tasks/changelog-version.sh
  [ "$status" -ne 0 ]
}
