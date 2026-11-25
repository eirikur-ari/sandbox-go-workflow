#!/usr/bin/env bats

load ../helpers

@test "host builds a static, reproducible binary for the host platform in the workspace" {
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script tasks/build.sh
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/bin/darwin_arm64/dummy" ]
  [[ "$output" == *"Building darwin/arm64"* ]]
  grep -qx "build GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 GOFLAGS=-mod=readonly cwd=$WORKSPACE_FOLDER args=build -trimpath -buildvcs=false -ldflags -s -w -o bin/darwin_arm64/dummy ./cmd" "$TEST_TMP/go.log"
}

@test "host fails without building when the host platform cannot be determined" {
  GO_ENV_FAIL=1 run_script tasks/build.sh
  [ "$status" -ne 0 ]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "host fails when the build fails" {
  GO_BUILD_FAIL=1 run_script tasks/build.sh
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/bin/linux_amd64/dummy" ]
}

@test "host builds into BIN_DIR as BINARY_NAME" {
  BIN_DIR=out BINARY_NAME=tool run_script tasks/build.sh
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/out/linux_amd64/tool" ]
}
