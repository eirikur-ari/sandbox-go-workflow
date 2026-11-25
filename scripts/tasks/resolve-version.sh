#!/usr/bin/env bash
# Resolves the release version, and prints it as version, releasable and reason lines, with an empty version when there is none.
# The version is REQUESTED_VERSION when it is set, and then it must be the latest version in the changelog.
# Otherwise it is the latest version in the changelog when that is newer than the latest release tag merged into the branch, and none when it is not.
# It needs the full git history for that. It validates nothing else about the version.
set -euo pipefail

# Prints the version of the latest release in the changelog
function changelogVersion() {
  bash scripts/task.sh changelog-version
}

# Prints the version of the latest release tag merged into the current branch, nothing when there is none, and exits when the history is shallow
function latestTagVersion() {
  local shallow tags tag

  shallow=$(git rev-parse --is-shallow-repository) || exit 1
  if [[ "$shallow" == "true" ]]; then
    echo "the full git history is needed to find the latest tag, but the repository is shallow" >&2
    exit 1
  fi
  tags=$(git tag --merged HEAD --list 'v*' --sort=-v:refname) || exit 1
  tag=$(sed -n '1p' <<< "$tags")
  echo "${tag#v}"
}

# Succeeds when the given version is newer than the version of the latest release tag, or when there is no release tag
function isNewerThanLatestTag() {
  local version="$1" tag_version

  tag_version=$(latestTagVersion) || exit 1
  [[ -z "$tag_version" ]] && return 0
  [[ "$version" != "$tag_version" && "$(printf '%s\n%s\n' "$version" "$tag_version" | LC_ALL=C sort -V | tail -n 1)" == "$version" ]]
}

# Prints the release version, which is empty when there is none, whether it is releasable, and the reason
function printResult() {
  local version="$1" releasable="$2" reason="$3"

  echo "version=$version"
  echo "releasable=$releasable"
  echo "reason=$reason"
}

# Prints the requested version as the release version, and fails unless it is the latest version in the changelog
function resolveRequested() {
  local changelog_version

  changelog_version=$(changelogVersion) || exit 1
  if [[ "$REQUESTED_VERSION" != "$changelog_version" ]]; then
    echo "version '$REQUESTED_VERSION' is not the latest version in the changelog, '$changelog_version'" >&2
    exit 1
  fi
  printResult "$REQUESTED_VERSION" true "requested version"
}

# Prints the latest version of the changelog as the release version when it is newer than the latest tag, and otherwise no version
function resolveFromChangelog() {
  local changelog_version

  if ! changelog_version=$(changelogVersion); then
    printResult "" false "no release version found in the changelog"
  elif isNewerThanLatestTag "$changelog_version"; then
    printResult "$changelog_version" true "the changelog version is newer than the latest tag"
  else
    printResult "" false "the changelog version $changelog_version is not newer than the latest tag"
  fi
}

# Resolves the release version, from the request or else from the changelog
function resolveVersion() {
  if [[ -n "${REQUESTED_VERSION:-}" ]]; then
    resolveRequested
  else
    resolveFromChangelog
  fi
}

# Prints the release version
function main() {
  resolveVersion
}

main
