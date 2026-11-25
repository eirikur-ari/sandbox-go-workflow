#!/usr/bin/env bats

load helpers

@test "runs the task of scripts when the task has no adapter" {
  install_dispatchers
  run_task build-all
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_TMP/calls.log")" = "core args=build-all cwd=$TEST_TMP/work" ]
}

@test "passes every argument on to the task of scripts" {
  install_dispatchers
  run_task dev-copy "a file" /tmp/dest
  [ "$status" -eq 0 ]
  grep -qx "core args=dev-copy a file /tmp/dest cwd=$TEST_TMP/work" "$TEST_TMP/calls.log"
}

@test "runs the adapter instead of the task when the task has one" {
  install_dispatchers
  add_adapter resolve-version 'echo "adapter args=$*"'
  run_task resolve-version one two
  [ "$status" -eq 0 ]
  [ "$output" = "adapter args=one two" ]
  [ ! -e "$TEST_TMP/calls.log" ]
}

@test "runs the adapter from the root of the repository" {
  install_dispatchers
  add_adapter where 'pwd'
  cd "$TEST_TMP"
  run_task where
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TMP/work" ]
}

@test "other tasks still go to the task of scripts when another task has an adapter" {
  install_dispatchers
  add_adapter resolve-version 'echo adapter'
  run_task package
  grep -qx "core args=package cwd=$TEST_TMP/work" "$TEST_TMP/calls.log"
}

@test "list, help and no task are answered by the dispatcher of scripts" {
  install_dispatchers
  run_task list --names
  run_task help build
  run_task
  [ "$(cat "$TEST_TMP/calls.log")" = $'core args=list --names cwd='"$TEST_TMP"$'/work\ncore args=help build cwd='"$TEST_TMP"$'/work\ncore args= cwd='"$TEST_TMP/work" ]
}

@test "fails with the status of the task of scripts" {
  install_dispatchers
  FAKE_SCRIPT_EXIT=3 run_task build
  [ "$status" -eq 3 ]
}

@test "fails with the status of the adapter" {
  install_dispatchers
  add_adapter resolve-version 'exit 4'
  run_task resolve-version
  [ "$status" -eq 4 ]
}

@test "a name that is not a task name is left to the dispatcher of scripts, never run as an adapter" {
  install_dispatchers
  printf '#!/usr/bin/env bash\ntouch "%s/ran"\n' "$TEST_TMP" > "$TEST_TMP/work/.github/scripts/x.sh"
  run_task ../x
  [ "$status" -eq 0 ]
  grep -qx "core args=../x cwd=$TEST_TMP/work" "$TEST_TMP/calls.log"
  [ ! -e "$TEST_TMP/ran" ]
}
