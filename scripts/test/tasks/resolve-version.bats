#!/usr/bin/env bats

load ../helpers

# Installs the dispatcher with a changelog-version task that prints CHANGELOG_VERSION, or fails when CHANGELOG_VERSION_FAIL is set
function version_task() {
  install_dispatcher
  add_task changelog-version "Prints the version." 'if [[ -n "${CHANGELOG_VERSION_FAIL:-}" ]]; then echo "no versions in changelog" >&2; exit 1; fi
echo "${CHANGELOG_VERSION:-1.2.3}"'
}

# Prints the three result lines the task prints for the given version, releasable and reason
function result() {
  printf 'version=%s\nreleasable=%s\nreason=%s' "$1" "$2" "$3"
}

@test "requested version that is the latest in the changelog is the release version" {
  version_task
  REQUESTED_VERSION=1.2.3 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result 1.2.3 true "requested version")" ]
}

@test "requested version that is not the latest in the changelog fails" {
  version_task
  REQUESTED_VERSION=1.2.2 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"is not the latest version in the changelog, '1.2.3'"* ]]
  [[ "$output" != *"version="* ]]
}

@test "requested version fails when the changelog version cannot be read" {
  version_task
  CHANGELOG_VERSION_FAIL=1 REQUESTED_VERSION=1.2.3 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 1 ]
}

@test "requested version is only resolved, not validated, and the git tags are not looked at" {
  version_task
  GIT_FAIL=1 CHANGELOG_VERSION=1.2 REQUESTED_VERSION=1.2 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result 1.2 true "requested version")" ]
  [ ! -e "$TEST_TMP/git.log" ]
}

@test "without a requested version, a changelog version newer than the latest tag is the release version" {
  version_task
  GIT_TAGS=v1.2.2 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result 1.2.3 true "the changelog version is newer than the latest tag")" ]
}

@test "without a requested version, a changelog version is the release version when there is no tag" {
  version_task
  CHANGELOG_VERSION=1.0.0 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result 1.0.0 true "the changelog version is newer than the latest tag")" ]
}

@test "without a requested version, a changelog version equal to the latest tag gives no version" {
  version_task
  GIT_TAGS=v1.2.3 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result "" false "the changelog version 1.2.3 is not newer than the latest tag")" ]
}

@test "without a requested version, a changelog version older than the latest tag gives no version" {
  version_task
  GIT_TAGS=$'v1.2.0\nv1.3.0' run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [ "$output" = "$(result "" false "the changelog version 1.2.3 is not newer than the latest tag")" ]
}

@test "without a requested version, versions are compared by number, not as text" {
  version_task
  GIT_TAGS=$'v1.9.0\nv1.10.0' CHANGELOG_VERSION=1.9.5 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"releasable=false"* ]]
  GIT_TAGS=$'v1.9.0\nv1.10.0' CHANGELOG_VERSION=1.10.1 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"version=1.10.1"* ]]
  [[ "$output" == *"releasable=true"* ]]
}

@test "without a requested version, a changelog without a release gives no version" {
  version_task
  CHANGELOG_VERSION_FAIL=1 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"releasable=false"* ]]
  [[ "$output" == *"reason=no release version found in the changelog"* ]]
}

@test "without a requested version, a newer changelog version is only resolved, not validated" {
  version_task
  CHANGELOG_VERSION=1.2 GIT_TAGS=v1.0.0 run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"version=1.2"* ]]
  [[ "$output" == *"releasable=true"* ]]
}

@test "without a requested version, a shallow repository fails the run" {
  version_task
  GIT_SHALLOW=true run_in_workspace tasks/resolve-version.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"the repository is shallow"* ]]
  [[ "$output" != *"version="* ]]
}

@test "without a requested version, a failing git fails the run" {
  version_task
  GIT_FAIL=1 run_in_workspace tasks/resolve-version.sh
  [ "$status" -ne 0 ]
  [[ "$output" != *"version="* ]]
}
