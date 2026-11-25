#!/usr/bin/env bats

load ../helpers

@test "run fails when the binary does not exist" {
  run_script tasks/acceptance-test.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"the binary to test does not exist: $WORKSPACE_FOLDER/bin/linux_amd64/dummy"* ]]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "run fails when the binary is not executable" {
  mkdir -p "$WORKSPACE_FOLDER/bin/linux_amd64"
  echo binary > "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  run_script tasks/acceptance-test.sh
  [ "$status" -eq 1 ]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "run runs the acceptance tests against the binary of the host platform in BIN_DIR from the workspace" {
  mkdir -p "$WORKSPACE_FOLDER/bin/linux_amd64"
  echo binary > "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  chmod +x "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  run_script tasks/acceptance-test.sh
  [ "$status" -eq 0 ]
  grep -qx "test APP_BINARY=$WORKSPACE_FOLDER/bin/linux_amd64/dummy cwd=$WORKSPACE_FOLDER args=test -v -tags acceptance -run TestAcceptance -count=1 ./..." "$TEST_TMP/go.log"
}

@test "run uses APP_BINARY when it is set" {
  echo binary > "$TEST_TMP/mybinary"
  chmod +x "$TEST_TMP/mybinary"
  APP_BINARY="$TEST_TMP/mybinary" run_script tasks/acceptance-test.sh
  [ "$status" -eq 0 ]
  grep -q "^test APP_BINARY=$TEST_TMP/mybinary " "$TEST_TMP/go.log"
}

@test "run fails when the acceptance tests fail" {
  mkdir -p "$WORKSPACE_FOLDER/bin/linux_amd64"
  echo binary > "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  chmod +x "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  GO_TEST_FAIL=1 run_script tasks/acceptance-test.sh
  [ "$status" -ne 0 ]
}

@test "the default binary is the one of the platform go reports" {
  mkdir -p "$WORKSPACE_FOLDER/bin/darwin_arm64"
  echo binary > "$WORKSPACE_FOLDER/bin/darwin_arm64/dummy"
  chmod +x "$WORKSPACE_FOLDER/bin/darwin_arm64/dummy"
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script tasks/acceptance-test.sh
  [ "$status" -eq 0 ]
  grep -q "^test APP_BINARY=$WORKSPACE_FOLDER/bin/darwin_arm64/dummy " "$TEST_TMP/go.log"
}
