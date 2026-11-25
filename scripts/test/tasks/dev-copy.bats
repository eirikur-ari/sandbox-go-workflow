#!/usr/bin/env bats

load ../helpers

@test "copy without a path exits 2" {
  run_script tasks/dev-copy.sh
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected the path of the file or directory to copy"* ]]
}

@test "copy of a path that does not exist exits 2" {
  run_script tasks/dev-copy.sh "$TEST_TMP/missing"
  [ "$status" -eq 2 ]
  [[ "$output" == *"does not exist: $TEST_TMP/missing"* ]]
}

@test "copy fails when no devcontainer is running" {
  echo hello > "$TEST_TMP/hello.txt"
  run_script tasks/dev-copy.sh "$TEST_TMP/hello.txt" "$TEST_TMP/dest"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No running devcontainer found."* ]]
  [ ! -e "$TEST_TMP/dest" ]
}

@test "copy puts a file into the destination" {
  echo hello > "$TEST_TMP/hello.txt"
  DOCKER_PS_IDS=abc run_script tasks/dev-copy.sh "$TEST_TMP/hello.txt" "$TEST_TMP/dest"
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/dest/hello.txt")" = hello ]
}

@test "copy puts the contents of a directory into the destination" {
  mkdir -p "$TEST_TMP/src/sub"
  echo a > "$TEST_TMP/src/a.txt"
  echo b > "$TEST_TMP/src/sub/b.txt"
  DOCKER_PS_IDS=abc run_script tasks/dev-copy.sh "$TEST_TMP/src" "$TEST_TMP/dest"
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/dest/a.txt")" = a ]
  [ "$(cat "$TEST_TMP/dest/sub/b.txt")" = b ]
  [ ! -e "$TEST_TMP/dest/src" ]
}

@test "copy goes to /home/sandbox/tmp in the running container by default" {
  echo hello > "$TEST_TMP/hello.txt"
  DOCKER_EXEC_DRYRUN=1 DOCKER_PS_IDS=abc run_script tasks/dev-copy.sh "$TEST_TMP/hello.txt"
  [ "$status" -eq 0 ]
  grep -qx "docker exec abc mkdir -p /home/sandbox/tmp" "$TEST_TMP/docker.log"
  grep -qx "docker exec -i abc tar -C /home/sandbox/tmp -xf -" "$TEST_TMP/docker.log"
}

@test "dev-copy takes the source and the destination from SOURCE and DESTINATION" {
  echo hello > "$TEST_TMP/hello.txt"
  SOURCE="$TEST_TMP/hello.txt" DESTINATION="$TEST_TMP/dest" DOCKER_PS_IDS=abc run_script tasks/dev-copy.sh
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/dest/hello.txt")" = hello ]
}

@test "dev-copy prefers its arguments to SOURCE and DESTINATION" {
  echo hello > "$TEST_TMP/hello.txt"
  echo other > "$TEST_TMP/other.txt"
  SOURCE="$TEST_TMP/other.txt" DESTINATION="$TEST_TMP/ignored" DOCKER_PS_IDS=abc run_script tasks/dev-copy.sh "$TEST_TMP/hello.txt" "$TEST_TMP/dest"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMP/dest/hello.txt" ]
  [ ! -e "$TEST_TMP/ignored" ]
}
