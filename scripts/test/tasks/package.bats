#!/usr/bin/env bats

load ../helpers

# Creates the files package.sh gathers in the workspace, and the binary that build writes for the given platform, which is linux_amd64 by default
function seed_workspace() {
  local dir="${1:-bin}" name="${2:-dummy}" platform="${3:-linux_amd64}"

  echo license > "$WORKSPACE_FOLDER/LICENSE"
  echo readme > "$WORKSPACE_FOLDER/README.md"
  echo changelog > "$WORKSPACE_FOLDER/CHANGELOG.md"
  mkdir -p "$WORKSPACE_FOLDER/$dir/$platform"
  echo "host binary" > "$WORKSPACE_FOLDER/$dir/$platform/$name"
}

@test "archives the host binary, named dev when RELEASE_VERSION is not set and for the platform of go" {
  seed_workspace
  run_script tasks/package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" ]
}

@test "the archive is named for the platform go reports" {
  seed_workspace bin dummy darwin_arm64
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script tasks/package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/dist/dummy_dev_darwin_arm64.tar.gz" ]
}

@test "the archive is named for RELEASE_VERSION" {
  seed_workspace
  RELEASE_VERSION=1.2.3 run_script tasks/package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" ]
  [ ! -e "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" ]
}

@test "only the archive of the host platform is written" {
  seed_workspace
  run_script tasks/package.sh
  [ "$status" -eq 0 ]
  [ "$(ls "$WORKSPACE_FOLDER/build/dist")" = "dummy_dev_linux_amd64.tar.gz" ]
}

@test "the archive holds the host binary, license, readme and changelog" {
  seed_workspace
  run_script tasks/package.sh
  [ "$status" -eq 0 ]
  local entries entry
  entries=$(tar -tzf "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz")
  for entry in dummy LICENSE README.md CHANGELOG.md; do
    grep -qx "$entry" <<< "$entries" || { echo "'$entry' is not in the archive: $entries"; return 1; }
  done
  [ "$(tar -xzOf "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" dummy)" = "host binary" ]
}

@test "the paths follow BIN_DIR, BINARY_NAME and DIST_DIR" {
  seed_workspace out tool
  BIN_DIR=out BINARY_NAME=tool DIST_DIR=archives run_script tasks/package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/archives/tool_dev_linux_amd64.tar.gz" ]
  tar -tzf "$WORKSPACE_FOLDER/archives/tool_dev_linux_amd64.tar.gz" | grep -qx tool
}

@test "fails when the host binary does not exist" {
  seed_workspace
  rm "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  run_script tasks/package.sh
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" ]
}

@test "fails without an archive when the platform cannot be determined" {
  seed_workspace
  GO_ENV_FAIL=1 run_script tasks/package.sh
  [ "$status" -ne 0 ]
  [ -z "$(ls "$WORKSPACE_FOLDER/build/dist")" ]
}

@test "fails when the changelog is missing" {
  seed_workspace
  rm "$WORKSPACE_FOLDER/CHANGELOG.md"
  run_script tasks/package.sh
  [ "$status" -ne 0 ]
}
