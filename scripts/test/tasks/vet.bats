#!/usr/bin/env bats

load ../helpers

@test "vets every package, including the ones behind the integration and acceptance tags" {
  run_in_workspace tasks/vet.sh
  [ "$status" -eq 0 ]
  grep -qx "vet args=vet -tags integration acceptance ./..." "$TEST_TMP/go.log"
}

@test "fails when go vet fails" {
  GO_VET_FAIL=1 run_in_workspace tasks/vet.sh
  [ "$status" -ne 0 ]
}
