#!/usr/bin/env bats

load helpers

# Creates the files package.sh gathers in the workspace, and a binary for every target holding the platform it is for
function seed_workspace() {
  local target dir="${1:-bin}" name="${2:-dummy}"

  echo license > "$WORKSPACE_FOLDER/LICENSE"
  echo readme > "$WORKSPACE_FOLDER/README.md"
  echo changelog > "$WORKSPACE_FOLDER/CHANGELOG.md"
  for target in "${TARGET_PLATFORMS[@]}"; do
    mkdir -p "$WORKSPACE_FOLDER/$dir/${target%/*}_${target#*/}"
    echo "binary $target" > "$WORKSPACE_FOLDER/$dir/${target%/*}_${target#*/}/$name"
  done
}

@test "archives every target, named dev when RELEASE_VERSION is not set" {
  seed_workspace
  run_script package.sh
  [ "$status" -eq 0 ]
  local target
  for target in "${TARGET_PLATFORMS[@]}"; do
    [ -f "$WORKSPACE_FOLDER/build/dist/dummy_dev_${target%/*}_${target#*/}.tar.gz" ]
  done
}

@test "archives are named for RELEASE_VERSION" {
  seed_workspace
  RELEASE_VERSION=1.2.3 run_script package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" ]
  [ -f "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" ]
  [ ! -e "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" ]
}

@test "an archive holds the binary, license, readme and changelog" {
  seed_workspace
  run_script package.sh
  [ "$status" -eq 0 ]
  local entries
  entries=$(tar -tzf "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz")
  local entry
  for entry in dummy LICENSE README.md CHANGELOG.md; do
    grep -qx "$entry" <<< "$entries" || { echo "'$entry' is not in the archive: $entries"; return 1; }
  done
}

@test "an archive holds the binary of its own platform only" {
  seed_workspace
  run_script package.sh
  [ "$status" -eq 0 ]
  local target
  for target in "${TARGET_PLATFORMS[@]}"; do
    [ "$(tar -xzOf "$WORKSPACE_FOLDER/build/dist/dummy_dev_${target%/*}_${target#*/}.tar.gz" dummy)" = "binary $target" ]
  done
}

@test "archive paths follow BUILD_DIR, DIST_DIR and BINARY_NAME" {
  seed_workspace bin tool
  BINARY_NAME=tool DIST_DIR=archives run_script package.sh
  [ "$status" -eq 0 ]
  [ -f "$WORKSPACE_FOLDER/archives/tool_dev_linux_amd64.tar.gz" ]
  tar -tzf "$WORKSPACE_FOLDER/archives/tool_dev_linux_amd64.tar.gz" | grep -qx tool
}

@test "fails when the binary of a target is missing" {
  seed_workspace
  rm "$WORKSPACE_FOLDER/bin/darwin_arm64/dummy"
  run_script package.sh
  [ "$status" -ne 0 ]
}

@test "fails when the changelog is missing" {
  seed_workspace
  rm "$WORKSPACE_FOLDER/CHANGELOG.md"
  run_script package.sh
  [ "$status" -ne 0 ]
}

@test "packaging again replaces the previous archives" {
  seed_workspace
  run_script package.sh
  echo "binary rebuilt" > "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  run_script package.sh
  [ "$status" -eq 0 ]
  [ "$(tar -xzOf "$WORKSPACE_FOLDER/build/dist/dummy_dev_linux_amd64.tar.gz" dummy)" = "binary rebuilt" ]
}
