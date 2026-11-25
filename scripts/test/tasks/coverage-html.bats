#!/usr/bin/env bats

load ../helpers

@test "generates the HTML report of the coverage profile in BUILD_DIR" {
  run_in_workspace tasks/coverage-html.sh
  [ "$status" -eq 0 ]
  grep -qx "tool args=tool cover -html=build/coverage.out -o build/coverage.html" "$TEST_TMP/go.log"
}

@test "follows BUILD_DIR" {
  BUILD_DIR=out run_in_workspace tasks/coverage-html.sh
  [ "$status" -eq 0 ]
  grep -qx "tool args=tool cover -html=out/coverage.out -o out/coverage.html" "$TEST_TMP/go.log"
}
