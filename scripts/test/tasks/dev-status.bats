#!/usr/bin/env bats

load ../helpers

# Start of the label filter the script uses to select the container of the workspace
FILTER="label=devcontainer.local_folder="

@test "status lists the containers of the workspace" {
  run_script tasks/dev-status.sh
  [ "$status" -eq 0 ]
  grep -q "^docker ps -a --filter $FILTER$WORKSPACE_FOLDER --format table" "$TEST_TMP/docker.log"
}
