#!/usr/bin/env bats

load helpers

# Prints the value of a variable after sourcing lib/config.sh in a fresh shell
function config_value() {
  bash -c 'source "$1/lib/config.sh" && echo "${!2}"' _ "$SCRIPTS" "$1"
}

@test "defaults" {
  unset WORKSPACE_FOLDER
  [ "$(config_value BINARY_NAME)" = dummy ]
  [ "$(config_value BUILD_DIR)" = build ]
  [ "$(config_value BIN_DIR)" = bin ]
  [ "$(config_value DIST_DIR)" = build/dist ]
  [ "$(config_value PACKAGE_DIR)" = build/package ]
}

@test "WORKSPACE_FOLDER defaults to the parent of the scripts directory" {
  unset WORKSPACE_FOLDER
  [ "$(config_value WORKSPACE_FOLDER)" = "$(cd "$SCRIPTS/.." && pwd)" ]
}

@test "each value is overridden by the environment variable of the same name" {
  BINARY_NAME=other BUILD_DIR=out BIN_DIR=binaries DIST_DIR=archives PACKAGE_DIR=staging
  export BINARY_NAME BUILD_DIR BIN_DIR DIST_DIR PACKAGE_DIR
  [ "$(config_value BINARY_NAME)" = other ]
  [ "$(config_value BUILD_DIR)" = out ]
  [ "$(config_value BIN_DIR)" = binaries ]
  [ "$(config_value DIST_DIR)" = archives ]
  [ "$(config_value PACKAGE_DIR)" = staging ]
  [ "$(config_value WORKSPACE_FOLDER)" = "$WORKSPACE_FOLDER" ]
}

@test "DIST_DIR and PACKAGE_DIR follow an overridden BUILD_DIR" {
  export BUILD_DIR=out
  [ "$(config_value DIST_DIR)" = out/dist ]
  [ "$(config_value PACKAGE_DIR)" = out/package ]
}

@test "TARGETS lists the four release platforms" {
  run bash -c 'source "$1/lib/config.sh" && printf "%s\n" "${TARGETS[@]}"' _ "$SCRIPTS"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' "${TARGET_PLATFORMS[@]}")" ]
}

@test "sourcing sets no shell options and prints nothing" {
  run bash -c 'source "$1/lib/config.sh" && echo "[$-]"' _ "$SCRIPTS"
  [ "$status" -eq 0 ]
  [[ "$output" != *e* && "$output" != *u* ]]
  [ "${#lines[@]}" -eq 1 ]
}
