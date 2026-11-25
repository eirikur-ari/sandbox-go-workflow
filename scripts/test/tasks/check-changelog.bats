#!/usr/bin/env bats

load ../helpers

# Installs the dispatcher with a changelog-unreleased task that prints CHANGELOG_UNRELEASED, or fails like a changelog without the section when CHANGELOG_UNRELEASED_FAIL is set
function unreleased_task() {
  install_dispatcher
  add_task changelog-unreleased "Prints the entries." 'if [[ -n "${CHANGELOG_UNRELEASED_FAIL:-}" ]]; then echo "no Unreleased section" >&2; exit 1; fi
printf "%s" "${CHANGELOG_UNRELEASED:-}"'
}

@test "passes when the Unreleased section has no entries" {
  unreleased_task
  run_in_workspace tasks/check-changelog.sh
  [ "$status" -eq 0 ]
}

@test "fails when the Unreleased section has entries" {
  unreleased_task
  CHANGELOG_UNRELEASED="- a change" run_in_workspace tasks/check-changelog.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"the Unreleased section of the changelog has entries"* ]]
}

@test "fails when the changelog has no Unreleased section" {
  unreleased_task
  CHANGELOG_UNRELEASED_FAIL=1 run_in_workspace tasks/check-changelog.sh
  [ "$status" -eq 1 ]
}
