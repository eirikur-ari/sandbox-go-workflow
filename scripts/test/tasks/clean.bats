#!/usr/bin/env bats

load ../helpers

@test "removes BIN_DIR and BUILD_DIR and nothing else" {
  mkdir -p "$WORKSPACE_FOLDER/bin" "$WORKSPACE_FOLDER/build/dist"
  echo binary > "$WORKSPACE_FOLDER/bin/dummy"
  echo keep > "$WORKSPACE_FOLDER/keep.txt"
  run_in_workspace tasks/clean.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running clean..."* ]]
  [ ! -e "$WORKSPACE_FOLDER/bin" ]
  [ ! -e "$WORKSPACE_FOLDER/build" ]
  [ -f "$WORKSPACE_FOLDER/keep.txt" ]
}

@test "follows BIN_DIR and BUILD_DIR" {
  mkdir -p "$WORKSPACE_FOLDER/binaries" "$WORKSPACE_FOLDER/out" "$WORKSPACE_FOLDER/bin"
  BIN_DIR=binaries BUILD_DIR=out run_in_workspace tasks/clean.sh
  [ "$status" -eq 0 ]
  [ ! -e "$WORKSPACE_FOLDER/binaries" ]
  [ ! -e "$WORKSPACE_FOLDER/out" ]
  [ -d "$WORKSPACE_FOLDER/bin" ]
}

@test "succeeds when there is nothing to remove" {
  run_in_workspace tasks/clean.sh
  [ "$status" -eq 0 ]
}
