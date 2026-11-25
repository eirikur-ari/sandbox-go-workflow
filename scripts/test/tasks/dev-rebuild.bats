#!/usr/bin/env bats

load ../helpers

@test "rebuild recreates the devcontainer without the build cache" {
  run_script tasks/dev-rebuild.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer up --workspace-folder $WORKSPACE_FOLDER --remove-existing-container --build-no-cache" ]
}
