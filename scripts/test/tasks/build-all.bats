#!/usr/bin/env bats

load ../helpers

@test "all builds every target into its own directory" {
  run_script tasks/build-all.sh
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
  GO_BUILD_FAIL=1 run_script tasks/build-all.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Building linux/amd64"* ]]
  [[ "$output" != *"Building linux/arm64"* ]]
}

@test "all builds into BIN_DIR as BINARY_NAME" {
  BIN_DIR=out BINARY_NAME=tool run_script tasks/build-all.sh
  [ "$status" -eq 0 ]
  [ -x "$WORKSPACE_FOLDER/out/linux_amd64/tool" ]
}
