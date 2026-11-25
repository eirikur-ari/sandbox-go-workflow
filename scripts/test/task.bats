#!/usr/bin/env bats

load helpers

# Installs the dispatcher with two tasks
function two_tasks() {
  install_dispatcher
  add_task build "Builds the binary." 'echo built'
  add_task vet "Vets the code." 'echo vetted'
}

@test "without a task it exits 2 with how to use it and the tasks" {
  two_tasks
  run_task
  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: task.sh <task> [arguments]"* ]]
  [[ "$output" == *"build"*"Builds the binary."* ]]
  [[ "$output" == *"vet"*"Vets the code."* ]]
}

@test "list prints every task with its description" {
  two_tasks
  run_task list
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ ^build[[:space:]]+Builds\ the\ binary\.$ ]]
  [[ "${lines[1]}" =~ ^vet[[:space:]]+Vets\ the\ code\.$ ]]
  [ "${#lines[@]}" -eq 2 ]
}

@test "list --names prints only the names" {
  two_tasks
  run_task list --names
  [ "$status" -eq 0 ]
  [ "$output" = $'build\nvet' ]
}

@test "list prints nothing when there are no tasks" {
  install_dispatcher
  run_task list
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the description is the second line of the task file" {
  install_dispatcher
  printf '#!/usr/bin/env bash\n# Second line.\n# Third line.\necho hi\n' > "$WORKSPACE_FOLDER/scripts/tasks/first.sh"
  run_task help first
  [ "$status" -eq 0 ]
  [ "$output" = "Second line." ]
}

@test "help without a task prints how to use it" {
  two_tasks
  run_task help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: task.sh <task> [arguments]"* ]]
  [[ "$output" == *"Builds the binary."* ]]
}

@test "help of an unknown task exits 2" {
  two_tasks
  run_task help nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown task 'nope'"* ]]
}

@test "runs the task and prints its output" {
  two_tasks
  run_task build
  [ "$status" -eq 0 ]
  [ "$output" = "built" ]
}

@test "passes the arguments after the task name on to the task" {
  install_dispatcher
  add_task echo-args "Prints its arguments." 'echo "args=$*"'
  run_task echo-args one "two words"
  [ "$status" -eq 0 ]
  [ "$output" = "args=one two words" ]
}

@test "runs the task from the workspace whatever the current directory" {
  install_dispatcher
  add_task where "Prints the directory." 'pwd'
  cd "$TEST_TMP"
  run_task where
  [ "$status" -eq 0 ]
  [ "$output" = "$WORKSPACE_FOLDER" ]
}

@test "the environment reaches the task" {
  install_dispatcher
  add_task show-env "Prints a variable." 'echo "value=$SOME_VALUE"'
  SOME_VALUE=42 run_task show-env
  [ "$output" = "value=42" ]
}

@test "fails with the status of the task" {
  install_dispatcher
  add_task fail "Fails with 3." 'exit 3'
  run_task fail
  [ "$status" -eq 3 ]
}

@test "an unknown task exits 2 and lists the tasks" {
  two_tasks
  run_task nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown task 'nope', the tasks are:"* ]]
  [[ "$output" == *"Builds the binary."* ]]
}

@test "a name that is not a task name never runs anything" {
  two_tasks
  printf '#!/usr/bin/env bash\ntouch "%s/ran"\n' "$TEST_TMP" > "$WORKSPACE_FOLDER/scripts/outside.sh"
  local name
  for name in ../outside "a b" Build "-x" "build/../vet"; do
    run_task "$name"
    [ "$status" -eq 2 ] || { echo "'$name' gave status $status"; return 1; }
  done
  [ ! -e "$TEST_TMP/ran" ]
}
