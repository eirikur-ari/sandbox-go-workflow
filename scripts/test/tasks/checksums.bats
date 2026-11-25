#!/usr/bin/env bats

load ../helpers

@test "writes the checksums of the archives next to them" {
  mkdir -p "$WORKSPACE_FOLDER/build/dist"
  echo one > "$WORKSPACE_FOLDER/build/dist/a.tar.gz"
  echo two > "$WORKSPACE_FOLDER/build/dist/b.tar.gz"
  run_in_workspace tasks/checksums.sh
  [ "$status" -eq 0 ]
  [ "$(wc -l < "$WORKSPACE_FOLDER/build/dist/checksums.txt")" -eq 2 ]
  (cd "$WORKSPACE_FOLDER/build/dist" && sha256sum --check --quiet checksums.txt)
}

@test "follows DIST_DIR" {
  mkdir -p "$WORKSPACE_FOLDER/archives"
  echo one > "$WORKSPACE_FOLDER/archives/a.tar.gz"
  DIST_DIR=archives run_in_workspace tasks/checksums.sh
  [ "$status" -eq 0 ]
  grep -q "a.tar.gz" "$WORKSPACE_FOLDER/archives/checksums.txt"
}

@test "fails when there are no archives" {
  mkdir -p "$WORKSPACE_FOLDER/build/dist"
  run_in_workspace tasks/checksums.sh
  [ "$status" -ne 0 ]
}

@test "fails when there is no distribution directory" {
  run_in_workspace tasks/checksums.sh
  [ "$status" -ne 0 ]
}
