#!/usr/bin/env bats

load ../helpers

@test "passes when every file is formatted" {
  run_in_workspace tasks/fmt-lint.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checking source formatting"* ]]
  grep -qx "gofmt -l ." "$TEST_TMP/go.log"
}

@test "fails and lists the files that are not formatted" {
  FAKE_UNFORMATTED=$'a.go\nb.go' run_in_workspace tasks/fmt-lint.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"The following files are not gofmt-formatted:"* ]]
  [[ "$output" == *"a.go"* && "$output" == *"b.go"* ]]
}
