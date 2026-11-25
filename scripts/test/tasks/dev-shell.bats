#!/usr/bin/env bats

load ../helpers

@test "shell opens zsh by default" {
  run_script tasks/dev-shell.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer exec --workspace-folder $WORKSPACE_FOLDER zsh" ]
}

@test "shell opens DC_SHELL when it is set" {
  DC_SHELL=bash run_script tasks/dev-shell.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer exec --workspace-folder $WORKSPACE_FOLDER bash" ]
}
