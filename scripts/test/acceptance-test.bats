#!/usr/bin/env bats

load helpers

@test "no argument exits 2 with the list of steps" {
  run_script acceptance-test.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be one of the following: extract, run"* ]]
}

@test "unknown argument exits 2" {
  run_script acceptance-test.sh nope
  [ "$status" -eq 2 ]
}

@test "extract unpacks the archive of this platform into the acceptance directory" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" linux.txt
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" darwin.txt
  run_script acceptance-test.sh extract
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/acceptance/linux.txt" ]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance/darwin.txt" ]
}

@test "extract selects the archive of the platform go reports" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" linux.txt
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" darwin.txt
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script acceptance-test.sh extract
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/acceptance/darwin.txt" ]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance/linux.txt" ]
}

@test "extract empties the acceptance directory first" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" linux.txt
  mkdir -p "$WORKSPACE_FOLDER/build/acceptance"
  echo stale > "$WORKSPACE_FOLDER/build/acceptance/stale.txt"
  run_script acceptance-test.sh extract
  [ "$status" -eq 0 ]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance/stale.txt" ]
  [ -f "$WORKSPACE_FOLDER/build/acceptance/linux.txt" ]
}

@test "extract unpacks into ACCEPTANCE_DIR when it is set" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" linux.txt
  ACCEPTANCE_DIR="$TEST_TMP/elsewhere" run_script acceptance-test.sh extract
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMP/elsewhere/linux.txt" ]
}

@test "extract finds the archive in DIST_DIR for the BINARY_NAME" {
  make_archive "$WORKSPACE_FOLDER/archives/tool_1.2.3_linux_amd64.tar.gz" linux.txt
  make_archive "$WORKSPACE_FOLDER/archives/dummy_1.2.3_linux_amd64.tar.gz" other.txt
  DIST_DIR=archives BINARY_NAME=tool run_script acceptance-test.sh extract
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/acceptance/linux.txt" ]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance/other.txt" ]
}

@test "extract fails when there is no archive for this platform" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" darwin.txt
  run_script acceptance-test.sh extract
  [ "$status" -eq 1 ]
  [[ "$output" == *"expected exactly one linux/amd64 archive in build/dist, found: none"* ]]
}

@test "extract fails when there is more than one archive for this platform" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" one.txt
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.4_linux_amd64.tar.gz" two.txt
  run_script acceptance-test.sh extract
  [ "$status" -eq 1 ]
  [[ "$output" == *"expected exactly one linux/amd64 archive"* ]]
  [[ "$output" == *"dummy_1.2.3_linux_amd64.tar.gz"* ]]
  [[ "$output" == *"dummy_1.2.4_linux_amd64.tar.gz"* ]]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance" ]
}

@test "extract fails when the distribution directory does not exist" {
  run_script acceptance-test.sh extract
  [ "$status" -ne 0 ]
}

@test "extract fails without extracting when the platform cannot be determined" {
  make_archive "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" linux.txt
  GO_ENV_FAIL=1 run_script acceptance-test.sh extract
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/build/acceptance" ]
}

@test "run fails when the binary does not exist" {
  run_script acceptance-test.sh run
  [ "$status" -eq 1 ]
  [[ "$output" == *"the binary to test does not exist: $WORKSPACE_FOLDER/bin/dummy"* ]]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "run fails when the binary is not executable" {
  mkdir -p "$WORKSPACE_FOLDER/bin"
  echo binary > "$WORKSPACE_FOLDER/bin/dummy"
  run_script acceptance-test.sh run
  [ "$status" -eq 1 ]
  [ ! -e "$TEST_TMP/go.log" ]
}

@test "run runs the acceptance tests against the binary in BIN_DIR from the workspace" {
  mkdir -p "$WORKSPACE_FOLDER/bin"
  echo binary > "$WORKSPACE_FOLDER/bin/dummy"
  chmod +x "$WORKSPACE_FOLDER/bin/dummy"
  run_script acceptance-test.sh run
  [ "$status" -eq 0 ]
  grep -qx "test DUMMY_BINARY=$WORKSPACE_FOLDER/bin/dummy cwd=$WORKSPACE_FOLDER args=test -v -tags acceptance -run TestAcceptance -count=1 ./..." "$TEST_TMP/go.log"
}

@test "run uses DUMMY_BINARY when it is set" {
  echo binary > "$TEST_TMP/mybinary"
  chmod +x "$TEST_TMP/mybinary"
  DUMMY_BINARY="$TEST_TMP/mybinary" run_script acceptance-test.sh run
  [ "$status" -eq 0 ]
  grep -q "^test DUMMY_BINARY=$TEST_TMP/mybinary " "$TEST_TMP/go.log"
}

@test "run fails when the acceptance tests fail" {
  mkdir -p "$WORKSPACE_FOLDER/bin"
  echo binary > "$WORKSPACE_FOLDER/bin/dummy"
  chmod +x "$WORKSPACE_FOLDER/bin/dummy"
  GO_TEST_FAIL=1 run_script acceptance-test.sh run
  [ "$status" -ne 0 ]
}
