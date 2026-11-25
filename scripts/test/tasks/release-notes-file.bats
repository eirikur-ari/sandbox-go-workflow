#!/usr/bin/env bats

load ../helpers

@test "writes the release notes to release-notes.md in BUILD_DIR" {
  install_dispatcher
  add_task release-notes-content "Prints the notes." 'echo "notes of $RELEASE_VERSION"'
  RELEASE_VERSION=1.2.3 run_in_workspace tasks/release-notes-file.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$WORKSPACE_FOLDER/build/release-notes.md")" = "notes of 1.2.3" ]
}

@test "follows BUILD_DIR" {
  install_dispatcher
  add_task release-notes-content "Prints the notes." 'echo notes'
  BUILD_DIR=out run_in_workspace tasks/release-notes-file.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/out/release-notes.md" ]
}

@test "removes the file and fails when there are no release notes" {
  install_dispatcher
  add_task release-notes-content "Prints the notes." 'echo partial; exit 1'
  run_in_workspace tasks/release-notes-file.sh
  [ "$status" -eq 1 ]
  [ ! -e "$WORKSPACE_FOLDER/build/release-notes.md" ]
}
