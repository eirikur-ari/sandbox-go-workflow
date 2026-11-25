#!/usr/bin/env bats

load ../helpers

# Start of the label filter the script uses to select the container of the workspace
FILTER="label=devcontainer.local_folder="

@test "stop reports when no devcontainer is running" {
  run_script tasks/dev-stop.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"No running devcontainer found."* ]]
  ! grep -q '^docker stop' "$TEST_TMP/docker.log"
}

@test "stop stops every running container of the workspace" {
  DOCKER_PS_IDS=$'abc\ndef' run_script tasks/dev-stop.sh
  [ "$status" -eq 0 ]
  grep -qx "docker ps -q --filter $FILTER$WORKSPACE_FOLDER" "$TEST_TMP/docker.log"
  grep -qx "docker stop abc def" "$TEST_TMP/docker.log"
}
