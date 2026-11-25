#!/usr/bin/env bats

load ../helpers

@test "prints only the entries of the Unreleased section" {
  write_standard_changelog
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ "$output" = "- Unreleased entry" ]
}

@test "leaves out blank lines, subsection headings and comments" {
  write_changelog <<'EOF'
## [Unreleased]

<!-- Add entries below -->

### Added

- First entry

### Fixed

- Second entry
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ "$output" = $'- First entry\n- Second entry' ]
}

@test "keeps the continuation lines of an entry" {
  write_changelog <<'EOF'
## [Unreleased]

- An entry that goes on
  on a second line
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ "$output" = $'- An entry that goes on\n  on a second line' ]
}

@test "prints nothing and succeeds when the section has no entries" {
  write_changelog <<'EOF'
## [Unreleased]

### Added

<!-- Nothing yet -->

## [1.2.3] - 2026-01-02

- Released entry
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "stops at the link references when the Unreleased section is the last section" {
  write_changelog <<'EOF'
## [Unreleased]

- Only entry

[Unreleased]: https://example.com/compare/v1.2.3...HEAD
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ "$output" = "- Only entry" ]
}

@test "does not print the entries of a release" {
  write_changelog <<'EOF'
## [1.2.3] - 2026-01-02

- Released entry

## [Unreleased]

- New entry

## [1.2.2] - 2026-01-01

- Older entry
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 0 ]
  [ "$output" = "- New entry" ]
}

@test "fails when the changelog has no Unreleased section" {
  write_changelog <<'EOF'
## [1.2.3] - 2026-01-02

- Released entry
EOF
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"CHANGELOG.md has no Unreleased section"* ]]
}

@test "fails when there is no changelog" {
  run_in_workspace tasks/changelog-unreleased.sh
  [ "$status" -ne 0 ]
}
