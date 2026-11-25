#!/usr/bin/env bats

load ../helpers

# Creates an archive of a package at the given path, holding the binary with the given content, named dummy unless a name is given, a license and a readme
function make_package() {
  local archive="$1" text="$2" name="${3:-dummy}" content

  content="$(mktemp -d)"
  echo "$text" > "$content/$name"
  chmod +x "$content/$name"
  echo license > "$content/LICENSE"
  echo readme > "$content/README.md"
  mkdir -p "$(dirname "$archive")"
  tar -czf "$archive" -C "$content" -- "$name" LICENSE README.md
  rm -rf "${content:?}"
}

@test "unpacks the binary of the archive of this platform into BIN_DIR/<goos>_<goarch>/" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "linux binary"
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" "darwin binary"
  run_script tasks/acceptance-extract.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$WORKSPACE_FOLDER/bin/linux_amd64/dummy")" = "linux binary" ]
  [ -x "$WORKSPACE_FOLDER/bin/linux_amd64/dummy" ]
  [ ! -e "$WORKSPACE_FOLDER/bin/darwin_arm64" ]
}

@test "selects the archive of the platform go reports" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "linux binary"
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" "darwin binary"
  FAKE_GOOS=darwin FAKE_GOARCH=arm64 run_script tasks/acceptance-extract.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$WORKSPACE_FOLDER/bin/darwin_arm64/dummy")" = "darwin binary" ]
  [ ! -e "$WORKSPACE_FOLDER/bin/linux_amd64" ]
}

@test "unpacks only the binary, not the other files of the archive" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "linux binary"
  run_script tasks/acceptance-extract.sh
  [ "$status" -eq 0 ]
  [ "$(ls "$WORKSPACE_FOLDER/bin/linux_amd64")" = "dummy" ]
}

@test "replaces the binary that is there" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "packaged binary"
  mkdir -p "$WORKSPACE_FOLDER/bin/linux_amd64"
  echo "built binary" > "$WORKSPACE_FOLDER/bin/linux_amd64/dummy"
  run_script tasks/acceptance-extract.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$WORKSPACE_FOLDER/bin/linux_amd64/dummy")" = "packaged binary" ]
}

@test "follows BIN_DIR, BINARY_NAME and DIST_DIR" {
  make_package "$WORKSPACE_FOLDER/archives/tool_1.2.3_linux_amd64.tar.gz" "tool binary" tool
  make_package "$WORKSPACE_FOLDER/archives/dummy_1.2.3_linux_amd64.tar.gz" "other binary"
  BIN_DIR=out BINARY_NAME=tool DIST_DIR=archives run_script tasks/acceptance-extract.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$WORKSPACE_FOLDER/out/linux_amd64/tool")" = "tool binary" ]
  [ ! -e "$WORKSPACE_FOLDER/out/linux_amd64/dummy" ]
}

@test "fails when there is no archive for this platform" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_darwin_arm64.tar.gz" "darwin binary"
  run_script tasks/acceptance-extract.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"expected exactly one linux/amd64 archive in build/dist, found: none"* ]]
}

@test "fails and unpacks nothing when there is more than one archive for this platform" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "one"
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.4_linux_amd64.tar.gz" "two"
  run_script tasks/acceptance-extract.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"expected exactly one linux/amd64 archive"* ]]
  [[ "$output" == *"dummy_1.2.3_linux_amd64.tar.gz"* && "$output" == *"dummy_1.2.4_linux_amd64.tar.gz"* ]]
  [ ! -e "$WORKSPACE_FOLDER/bin" ]
}

@test "fails when the distribution directory does not exist" {
  run_script tasks/acceptance-extract.sh
  [ "$status" -ne 0 ]
}

@test "fails and unpacks nothing when the platform cannot be determined" {
  make_package "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" "linux binary"
  GO_ENV_FAIL=1 run_script tasks/acceptance-extract.sh
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/bin" ]
}

@test "fails when the archive holds no binary" {
  local content
  content="$(mktemp -d)"
  echo license > "$content/LICENSE"
  mkdir -p "$WORKSPACE_FOLDER/build/dist"
  tar -czf "$WORKSPACE_FOLDER/build/dist/dummy_1.2.3_linux_amd64.tar.gz" -C "$content" LICENSE
  rm -rf "${content:?}"
  run_script tasks/acceptance-extract.sh
  [ "$status" -ne 0 ]
  [ ! -e "$WORKSPACE_FOLDER/bin/linux_amd64/dummy" ]
}
