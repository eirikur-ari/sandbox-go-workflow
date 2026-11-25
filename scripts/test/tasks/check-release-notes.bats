#!/usr/bin/env bats

load ../helpers

# Installs the dispatcher with a release-notes-content task that prints notes, or fails when NOTES_FAIL is set
function notes_task() {
  install_dispatcher
  add_task release-notes-content "Prints the notes." 'if [[ -n "${NOTES_FAIL:-}" ]]; then echo "no notes" >&2; exit 1; fi
echo "the notes of $RELEASE_VERSION"'
}

@test "fails with status 2 naming RELEASE_VERSION when it is missing" {
  notes_task
  unset RELEASE_VERSION
  run_in_workspace tasks/check-release-notes.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"RELEASE_VERSION"* ]]
}

@test "passes when the changelog has release notes, without printing them" {
  notes_task
  RELEASE_VERSION=1.2.3 run_in_workspace tasks/check-release-notes.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fails when the changelog has no release notes" {
  notes_task
  NOTES_FAIL=1 RELEASE_VERSION=1.2.3 run_in_workspace tasks/check-release-notes.sh
  [ "$status" -ne 0 ]
}
