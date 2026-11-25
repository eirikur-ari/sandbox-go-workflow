#!/usr/bin/env bats

load ../helpers

@test "start brings the devcontainer of the workspace up" {
  run_script tasks/dev-start.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer up --workspace-folder $WORKSPACE_FOLDER" ]
}
