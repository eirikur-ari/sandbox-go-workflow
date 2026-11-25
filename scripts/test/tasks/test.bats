#!/usr/bin/env bats

load ../helpers

@test "runs the unit and integration tests with the race detector" {
  run_in_workspace tasks/test.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running tests..."* ]]
  grep -q "args=test -v -tags integration -race -count=1 ./...$" "$TEST_TMP/go.log"
}

@test "fails when the tests fail" {
  GO_TEST_FAIL=1 run_in_workspace tasks/test.sh
  [ "$status" -ne 0 ]
}
