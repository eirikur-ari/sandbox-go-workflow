#!/usr/bin/env bats

load helpers

# Prints the root of the repository, which these tests inspect and do not copy
function repo_root() {
  cd "$SCRIPTS/.." && pwd
}

@test "every task has a make target that runs it last, and make help lists it" {
  local task help_output
  cd "$(repo_root)"
  run make help
  [ "$status" -eq 0 ]
  help_output="$output"
  for task in $(bash scripts/task.sh list --names); do
    grep -qE "^$task:( [a-z0-9 -]+)? ; @bash scripts/task\.sh $task$" Makefile || { echo "the Makefile has no target for the task '$task'"; return 1; }
    grep -qE "^$task +" <<< "$help_output" || { echo "make help does not list '$task'"; return 1; }
    run make --dry-run "$task"
    [ "$status" -eq 0 ]
    [ "${lines[-1]}" = "bash scripts/task.sh $task" ] || { echo "make $task ends with: ${lines[-1]}"; return 1; }
  done
}

@test "every make target is a task, help or an aggregate, and is declared phony" {
  local targets expected aggregates phony
  cd "$(repo_root)"
  targets="$(grep -E '^[a-z0-9-]+:' Makefile | grep -v '^\.PHONY' | sed 's/:.*//' | sort)"
  aggregates="$(grep -E '^[a-z0-9-]+:[^;]*$' Makefile | grep -v '^\.PHONY' | sed 's/:.*//' | sort)"
  expected="$( { echo help; bash scripts/task.sh list --names; echo "$aggregates"; } | sort)"
  [ "$targets" = "$expected" ] || { diff <(echo "$expected") <(echo "$targets"); return 1; }
  [ -z "$(comm -12 <(echo "$aggregates") <(bash scripts/task.sh list --names | sort))" ] || { echo "an aggregate has the name of a task"; return 1; }
  phony="$(grep '^\.PHONY:' Makefile | sed 's/^\.PHONY://' | tr ' ' '\n' | sed '/^$/d' | sort)"
  [ "$phony" = "$targets" ] || { diff <(echo "$targets") <(echo "$phony"); return 1; }
}

@test "every prerequisite in the Makefile is a target" {
  local line prerequisite targets
  cd "$(repo_root)"
  targets="$(grep -E '^[a-z0-9-]+:' Makefile | grep -v '^\.PHONY' | sed 's/:.*//')"
  while IFS= read -r line; do
    for prerequisite in $(sed -E 's/^[a-z0-9-]+://; s/ ;.*$//' <<< "$line"); do
      grep -qxF "$prerequisite" <<< "$targets" || { echo "'$prerequisite' in '$line' is not a target"; return 1; }
    done
  done < <(grep -E '^[a-z0-9-]+:' Makefile | grep -v '^\.PHONY')
}

@test "the Makefile has nothing but targets with their prerequisites, phony declarations and comments" {
  run grep -vE '^(#|$|\.PHONY:|([a-z0-9-]+):( [a-z0-9 -]+)? ; @bash scripts/task\.sh \2$|[a-z0-9-]+: [a-z0-9 -]+$)' "$(repo_root)/Makefile"
  [ "$status" -eq 1 ] || { echo "$output"; return 1; }
}

@test "workflows run tasks only through .github/scripts/task.sh" {
  local file
  for file in "$(repo_root)"/.github/workflows/*.yaml; do
    [[ "$file" != */pipeline.yaml ]] || continue
    run grep -nw make "$file"
    [ "$status" -eq 1 ] || { echo "$file mentions make: $output"; return 1; }
    run bash -c "grep -n 'scripts/' \"\$1\" | grep -v '\.github/scripts/task\.sh'" _ "$file"
    [ "$status" -eq 1 ] || { echo "$file calls a script directly: $output"; return 1; }
  done
}

@test "the tasks and libraries of scripts know nothing of GitHub" {
  local root
  root="$(repo_root)"
  run grep -rn 'GITHUB_' "$root/scripts/tasks" "$root/scripts/lib" "$root/scripts/task.sh"
  [ "$status" -eq 1 ] || { echo "$output"; return 1; }
}

@test "every GitHub adapter replaces a task of scripts" {
  local file
  for file in "$(repo_root)"/.github/scripts/tasks/*.sh; do
    [ -f "$(repo_root)/scripts/tasks/$(basename "$file")" ] || { echo "$file has no task to replace"; return 1; }
  done
}

@test "every task describes itself in one sentence on its second line" {
  local file
  for file in "$(repo_root)"/scripts/tasks/*.sh; do
    [[ "$(sed -n 2p "$file")" =~ ^#\ .+\.$ ]] || { echo "$file: '$(sed -n 2p "$file")'"; return 1; }
  done
}

@test "the GitHub entry point offers every task" {
  cd "$(repo_root)"
  run bash .github/scripts/task.sh list --names
  [ "$status" -eq 0 ]
  [ "$output" = "$(bash scripts/task.sh list --names)" ]
}

@test "every test file belongs to a file of the source it tests" {
  local root file relative source
  root="$(repo_root)"
  for file in $(cd "$root" && find scripts/test .github/scripts/test -name '*.bats' ! -name layers.bats | sort); do
    relative="${file#*/test/}"
    source="${file%%/test/*}/${relative%.bats}.sh"
    [ -f "$root/$source" ] || { echo "$file has no source at $source"; return 1; }
  done
}

@test "every task and every adapter has a test file" {
  local root file name
  root="$(repo_root)"
  for file in "$root"/scripts/tasks/*.sh; do
    name="$(basename "$file" .sh)"
    [ -f "$root/scripts/test/tasks/$name.bats" ] || { echo "the task $name has no test"; return 1; }
  done
  for file in "$root"/.github/scripts/tasks/*.sh; do
    name="$(basename "$file" .sh)"
    [ -f "$root/.github/scripts/test/tasks/$name.bats" ] || { echo "the adapter $name has no test"; return 1; }
  done
}
