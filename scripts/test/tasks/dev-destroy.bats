#!/usr/bin/env bats

load ../helpers

# Start of the label filter the script uses to select the container of the workspace
FILTER="label=devcontainer.local_folder="

@test "destroy reports when there is no devcontainer" {
  run_script tasks/dev-destroy.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"No devcontainer found."* ]]
  ! grep -q -e '^docker rm' "$TEST_TMP/docker.log"
}

@test "destroy removes the container, including stopped ones, and its image" {
  DOCKER_PS_IDS=abc DOCKER_INSPECT_OUT=sha256:img run_script tasks/dev-destroy.sh
  [ "$status" -eq 0 ]
  grep -qx "docker ps -aq --filter $FILTER$WORKSPACE_FOLDER" "$TEST_TMP/docker.log"
  grep -qx "docker rm -f abc" "$TEST_TMP/docker.log"
  grep -qx "docker rmi -f sha256:img" "$TEST_TMP/docker.log"
}

@test "destroy removes an image shared by several containers once" {
  DOCKER_PS_IDS=$'abc\ndef' DOCKER_INSPECT_OUT=$'sha256:img\nsha256:img' run_script tasks/dev-destroy.sh
  [ "$status" -eq 0 ]
  grep -qx "docker rm -f abc def" "$TEST_TMP/docker.log"
  [ "$(grep -c '^docker rmi' "$TEST_TMP/docker.log")" -eq 1 ]
  grep -qx "docker rmi -f sha256:img" "$TEST_TMP/docker.log"
}
