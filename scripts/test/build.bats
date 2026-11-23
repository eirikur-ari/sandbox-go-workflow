#!/usr/bin/env bats

load helpers

@test "no argument exits 2 with the list of modes" {
  run_script build.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be one of the following: host, all"* ]]
}

@test "unknown argument exits 2" {
  run_script build.sh nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing or unknown argument"* ]]
}

@test "host builds a static, reproducible binary for the host platform in the workspace" {
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script build.sh host
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/bin/dummy" ]
  grep -qx "build GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 GOFLAGS=-mod=readonly cwd=$WORKSPACE_FOLDER args=build -trimpath -buildvcs=false -ldflags -s -w -o bin/dummy ./cmd" "$TEST_TMP/go.log"
}

@test "host fails without building when the host platform cannot be determined" {
  GO_ENV_FAIL=1 run_script build.sh host
  [ "$status" -ne 0 ]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "host fails when the build fails" {
  GO_BUILD_FAIL=1 run_script build.sh host
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/bin/dummy" ]
}

@test "host builds into BIN_DIR as BINARY_NAME" {
  BIN_DIR=out BINARY_NAME=tool run_script build.sh host
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/out/tool" ]
}

@test "all builds every target into its own directory" {
  run_script build.sh all
  [ "$status" -eq 0 ]
  local target
  for target in "${TARGET_PLATFORMS[@]}"; do
    [[ "$output" == *"Building $target"* ]]
    [ -x "$WORKSPACE_FOLDER/bin/${target%/*}_${target#*/}/dummy" ]
    grep -q "build GOOS=${target%/*} GOARCH=${target#*/} CGO_ENABLED=0 .* -o bin/${target%/*}_${target#*/}/dummy ./cmd" "$TEST_TMP/go.log"
  done
  [ "$(grep -c '^build ' "$TEST_TMP/go.log")" -eq 4 ]
}

@test "all stops at the first target that fails to build" {
  GO_BUILD_FAIL=1 run_script build.sh all
  [ "$status" -ne 0 ]
  [[ "$output" == *"Building linux/amd64"* ]]
  [[ "$output" != *"Building linux/arm64"* ]]
}

@test "all builds into BIN_DIR as BINARY_NAME" {
  BIN_DIR=out BINARY_NAME=tool run_script build.sh all
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/out/linux_amd64/tool" ]
}
