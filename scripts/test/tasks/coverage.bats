#!/usr/bin/env bats

load ../helpers

@test "runs the tests with a coverage profile in BUILD_DIR, then prints the report" {
  run_in_workspace tasks/coverage.sh
  [ "$status" -eq 0 ]
  [ -d "$WORKSPACE_FOLDER/build" ]
  grep -q "args=test -v -tags integration -race -count=1 -coverprofile=build/coverage.out -covermode=atomic ./...$" "$TEST_TMP/go.log"
  grep -qx "tool args=tool cover -func=build/coverage.out" "$TEST_TMP/go.log"
  [[ "$output" == *"total:"* ]]
}

@test "follows BUILD_DIR" {
  BUILD_DIR=out run_in_workspace tasks/coverage.sh
  [ "$status" -eq 0 ]
  [ -d "$WORKSPACE_FOLDER/out" ]
  grep -q -e "-coverprofile=out/coverage.out" "$TEST_TMP/go.log"
}

@test "prints no report when the tests fail" {
  GO_TEST_FAIL=1 run_in_workspace tasks/coverage.sh
  [ "$status" -ne 0 ]
  [ ! -e "$TEST_TMP/go.log" ]
}
