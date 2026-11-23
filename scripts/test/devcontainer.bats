#!/usr/bin/env bats

load helpers

# Start of the label filter the script uses to select the container of the workspace
FILTER="label=devcontainer.local_folder="

@test "no argument exits 2 with the list of actions" {
  run_script devcontainer.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"start, rebuild, stop, shell, copy, destroy or status"* ]]
}

@test "unknown action exits 2" {
  run_script devcontainer.sh nope
  [ "$status" -eq 2 ]
}

@test "start brings the devcontainer of the workspace up" {
  run_script devcontainer.sh start
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer up --workspace-folder $WORKSPACE_FOLDER" ]
}

@test "rebuild recreates the devcontainer without the build cache" {
  run_script devcontainer.sh rebuild
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer up --workspace-folder $WORKSPACE_FOLDER --remove-existing-container --build-no-cache" ]
}

@test "stop reports when no devcontainer is running" {
  run_script devcontainer.sh stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"No running devcontainer found."* ]]
  ! grep -q '^docker stop' "$TEST_TMP/docker.log"
}

@test "stop stops every running container of the workspace" {
  DOCKER_PS_IDS=$'abc\ndef' run_script devcontainer.sh stop
  [ "$status" -eq 0 ]
  grep -qx "docker ps -q --filter $FILTER$WORKSPACE_FOLDER" "$TEST_TMP/docker.log"
  grep -qx "docker stop abc def" "$TEST_TMP/docker.log"
}

@test "shell opens zsh by default" {
  run_script devcontainer.sh shell
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer exec --workspace-folder $WORKSPACE_FOLDER zsh" ]
}

@test "shell opens DC_SHELL when it is set" {
  DC_SHELL=bash run_script devcontainer.sh shell
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/devcontainer.log")" = "devcontainer exec --workspace-folder $WORKSPACE_FOLDER bash" ]
}

@test "copy without a path exits 2" {
  run_script devcontainer.sh copy
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected the path of the file or directory to copy"* ]]
}

@test "copy of a path that does not exist exits 2" {
  run_script devcontainer.sh copy "$TEST_TMP/missing"
  [ "$status" -eq 2 ]
  [[ "$output" == *"does not exist: $TEST_TMP/missing"* ]]
}

@test "copy fails when no devcontainer is running" {
  echo hello > "$TEST_TMP/hello.txt"
  run_script devcontainer.sh copy "$TEST_TMP/hello.txt" "$TEST_TMP/dest"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No running devcontainer found."* ]]
  [ ! -e "$TEST_TMP/dest" ]
}

@test "copy puts a file into the destination" {
  echo hello > "$TEST_TMP/hello.txt"
  DOCKER_PS_IDS=abc run_script devcontainer.sh copy "$TEST_TMP/hello.txt" "$TEST_TMP/dest"
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/dest/hello.txt")" = hello ]
}

@test "copy puts the contents of a directory into the destination" {
  mkdir -p "$TEST_TMP/src/sub"
  echo a > "$TEST_TMP/src/a.txt"
  echo b > "$TEST_TMP/src/sub/b.txt"
  DOCKER_PS_IDS=abc run_script devcontainer.sh copy "$TEST_TMP/src" "$TEST_TMP/dest"
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/dest/a.txt")" = a ]
  [ "$(cat "$TEST_TMP/dest/sub/b.txt")" = b ]
  [ ! -e "$TEST_TMP/dest/src" ]
}

@test "copy goes to /home/sandbox/tmp in the running container by default" {
  echo hello > "$TEST_TMP/hello.txt"
  DOCKER_EXEC_DRYRUN=1 DOCKER_PS_IDS=abc run_script devcontainer.sh copy "$TEST_TMP/hello.txt"
  [ "$status" -eq 0 ]
  grep -qx "docker exec abc mkdir -p /home/sandbox/tmp" "$TEST_TMP/docker.log"
  grep -qx "docker exec -i abc tar -C /home/sandbox/tmp -xf -" "$TEST_TMP/docker.log"
}

@test "destroy reports when there is no devcontainer" {
  run_script devcontainer.sh destroy
  [ "$status" -eq 0 ]
  [[ "$output" == *"No devcontainer found."* ]]
  ! grep -q -e '^docker rm' "$TEST_TMP/docker.log"
}

@test "destroy removes the container, including stopped ones, and its image" {
  DOCKER_PS_IDS=abc DOCKER_INSPECT_OUT=sha256:img run_script devcontainer.sh destroy
  [ "$status" -eq 0 ]
  grep -qx "docker ps -aq --filter $FILTER$WORKSPACE_FOLDER" "$TEST_TMP/docker.log"
  grep -qx "docker rm -f abc" "$TEST_TMP/docker.log"
  grep -qx "docker rmi -f sha256:img" "$TEST_TMP/docker.log"
}

@test "destroy removes an image shared by several containers once" {
  DOCKER_PS_IDS=$'abc\ndef' DOCKER_INSPECT_OUT=$'sha256:img\nsha256:img' run_script devcontainer.sh destroy
  [ "$status" -eq 0 ]
  grep -qx "docker rm -f abc def" "$TEST_TMP/docker.log"
  [ "$(grep -c '^docker rmi' "$TEST_TMP/docker.log")" -eq 1 ]
  grep -qx "docker rmi -f sha256:img" "$TEST_TMP/docker.log"
}

@test "status lists the containers of the workspace" {
  run_script devcontainer.sh status
  [ "$status" -eq 0 ]
  grep -q "^docker ps -a --filter $FILTER$WORKSPACE_FOLDER --format table" "$TEST_TMP/docker.log"
}
