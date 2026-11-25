#!/usr/bin/env bats

load ../helpers

@test "prints the release notes file of BUILD_DIR" {
  mkdir -p "$WORKSPACE_FOLDER/build"
  echo "the notes" > "$WORKSPACE_FOLDER/build/release-notes.md"
  run_in_workspace tasks/release-notes.sh
  [ "$status" -eq 0 ]
  [ "$output" = "the notes" ]
}

@test "follows BUILD_DIR" {
  mkdir -p "$WORKSPACE_FOLDER/out"
  echo "other notes" > "$WORKSPACE_FOLDER/out/release-notes.md"
  BUILD_DIR=out run_in_workspace tasks/release-notes.sh
  [ "$status" -eq 0 ]
  [ "$output" = "other notes" ]
}

@test "fails when the release notes file does not exist" {
  run_in_workspace tasks/release-notes.sh
  [ "$status" -ne 0 ]
}
