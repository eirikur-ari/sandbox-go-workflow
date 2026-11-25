#!/usr/bin/env bats

load ../helpers

@test "writes the Go license and the module licenses to THIRD_PARTY_LICENSES in the package directory" {
  FAKE_LICENSE_FILES="github.com/a/mod/LICENSE" run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  local file="$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES"
  [ -f "$file" ]
  grep -qx "Go standard library and runtime" "$file"
  grep -qx "Go license text" "$file"
  grep -qx "github.com/a/mod/LICENSE" "$file"
  grep -qx "license text of github.com/a/mod/LICENSE" "$file"
}

@test "puts the Go license first and the module licenses in byte order" {
  FAKE_LICENSE_FILES="github.com/b/mod/LICENSE github.com/a/mod/LICENSE github.com/B/mod/LICENSE" run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  local headers
  headers=$(grep -E '^(Go standard library and runtime|github\.com/)' "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES")
  [ "$headers" = $'Go standard library and runtime\ngithub.com/B/mod/LICENSE\ngithub.com/a/mod/LICENSE\ngithub.com/b/mod/LICENSE' ]
}

@test "accepts license, notice and copying files" {
  FAKE_LICENSE_FILES="github.com/a/mod/LICENSE.md github.com/a/mod/NOTICE github.com/b/mod/COPYING.txt" run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  grep -qx "github.com/a/mod/NOTICE" "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES"
  grep -qx "github.com/b/mod/COPYING.txt" "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES"
}

@test "saves the licenses next to the package directory, with go-licenses at a fixed version" {
  FAKE_LICENSE_FILES="github.com/a/mod/LICENSE" run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  grep -q "^run cwd=$WORKSPACE_FOLDER args=run github.com/google/go-licenses/v2@v2.0.1 save " "$TEST_TMP/go.log"
  grep -q -e "--force --save_path=build/licenses$" "$TEST_TMP/go.log"
  [ -f "$WORKSPACE_FOLDER/build/licenses/github.com/a/mod/LICENSE" ]
}

@test "follows PACKAGE_DIR" {
  PACKAGE_DIR=out/pkg FAKE_LICENSE_FILES="github.com/a/mod/LICENSE" run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/out/pkg/THIRD_PARTY_LICENSES" ]
  grep -q -e "--save_path=out/licenses$" "$TEST_TMP/go.log"
}

@test "fails and writes nothing when go-licenses saves a file that is not a license" {
  FAKE_LICENSE_FILES="github.com/a/mod/LICENSE github.com/a/mod/README.md" run_script tasks/licenses.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"go-licenses saved files that are not licenses"* ]]
  [[ "$output" == *"./github.com/a/mod/README.md"* ]]
  [ ! -e "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES" ]
}

@test "succeeds and writes nothing when there are no third-party licenses" {
  run_script tasks/licenses.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"no third-party licenses found, nothing to write"* ]]
  [ ! -e "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES" ]
}

@test "fails when go-licenses fails" {
  GO_RUN_FAIL=1 FAKE_LICENSE_FILES="github.com/a/mod/LICENSE" run_script tasks/licenses.sh
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/build/package/THIRD_PARTY_LICENSES" ]
}
