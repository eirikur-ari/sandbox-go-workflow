#!/usr/bin/env bats

load ../helpers

@test "prints the total coverage percentage of the coverage profile" {
  run_in_workspace tasks/coverage-summary.sh
  [ "$status" -eq 0 ]
  [ "$output" = "85.0%" ]
  grep -qx "tool args=tool cover -func=build/coverage.out" "$TEST_TMP/go.log"
}

@test "follows BUILD_DIR" {
  BUILD_DIR=out run_in_workspace tasks/coverage-summary.sh
  [ "$status" -eq 0 ]
  grep -qx "tool args=tool cover -func=out/coverage.out" "$TEST_TMP/go.log"
}
