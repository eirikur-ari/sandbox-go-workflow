#!/usr/bin/env bash
# Runs one validation of the release version: branch, version-format, tag, release-notes or release.
# Every validation requires RELEASE_VERSION in the environment, except branch and release.
# branch requires GITHUB_REF and tag requires GITHUB_REPOSITORY and GH_TOKEN in the environment.
# release resolves the release version, which is REQUESTED_VERSION when it is set and otherwise the latest version in the changelog,
# and requires GITHUB_REF, GITHUB_REPOSITORY, GH_TOKEN, GITHUB_OUTPUT and GITHUB_STEP_SUMMARY in the environment.
set -euo pipefail

# Fails when a required environment variable is missing or empty
function setup() {
  local missing=() name
  for name in "$@"; do
    [[ -n "${!name:-}" ]] || missing+=("$name")
  done
  if (( ${#missing[@]} > 0 )); then
    echo "missing or empty environment variables: ${missing[*]}" >&2
    exit 2
  fi
}

# Fails unless the run was started from master
function branch() {
  setup GITHUB_REF
  if [[ "$GITHUB_REF" != "refs/heads/master" && "$GITHUB_REF" != "refs/heads/release/*" ]]; then
    echo "a release must be started from master or a release branch, not '$GITHUB_REF_NAME'"
    exit 1
  fi
}

# Fails unless the release version is MAJOR.MINOR.PATCH
function versionFormat() {
  setup RELEASE_VERSION
  if [[ ! "$RELEASE_VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "version '$RELEASE_VERSION' is not MAJOR.MINOR.PATCH"
    exit 1
  fi
}

# Succeeds when the release tag exists, fails when it does not, and exits when its lookup fails for any other reason than the tag not being found
function tagExists() {
  local tag_ref

  if tag_ref=$(gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/v$RELEASE_VERSION" 2>&1); then
    return 0
  elif [[ "$tag_ref" != *"HTTP 404"* ]]; then
    echo "$tag_ref" >&2
    exit 1
  fi
  return 1
}

# Fails when the release tag already exists
function tag() {
  setup RELEASE_VERSION GITHUB_REPOSITORY GH_TOKEN
  if tagExists; then
    echo "tag v$RELEASE_VERSION already exists"
    exit 1
  fi
}

# Fails when the changelog has no release notes for the release version
function releaseNotes() {
  setup RELEASE_VERSION
  make release-notes-content > /dev/null
}

# Prints the version of the latest release in the changelog
function changelogVersion() {
  bash scripts/changelog-version.sh
}

# Succeeds when the Unreleased section of the changelog has entries, and exits when the changelog has no Unreleased section
function unreleasedHasEntries() {
  local entries

  entries=$(bash scripts/changelog-unreleased.sh) || exit 1
  [[ -n "$entries" ]]
}

# Writes the release version and whether it is releasable to the step output, and the reason to the step summary
function writeResult() {
  local releasable="$1" reason="$2"

  {
    echo "version=$RELEASE_VERSION"
    echo "releasable=$releasable"
  } >> "$GITHUB_OUTPUT"
  {
    echo "### Release validation"
    echo
    echo "- Version: $RELEASE_VERSION"
    echo "- Releasable: $releasable ($reason)"
  } >> "$GITHUB_STEP_SUMMARY"
}

# Resolves the release version, validates it and writes whether it is releasable
# A requested version must be the latest in the changelog, have no tag and the changelog no unreleased entries, otherwise it fails
# Without a requested version it is not releasable when its tag exists or the changelog has unreleased entries
function release() {
  local changelog_version

  setup GITHUB_REF GITHUB_REPOSITORY GH_TOKEN GITHUB_OUTPUT GITHUB_STEP_SUMMARY
  branch
  changelog_version=$(changelogVersion) || exit 1
  RELEASE_VERSION="${REQUESTED_VERSION:-$changelog_version}"
  export RELEASE_VERSION
  versionFormat
  if [[ "$RELEASE_VERSION" != "$changelog_version" ]]; then
    echo "version '$RELEASE_VERSION' is not the latest version in the changelog, '$changelog_version'"
    exit 1
  fi
  releaseNotes

  if [[ -n "${REQUESTED_VERSION:-}" ]]; then
    tag
    if unreleasedHasEntries; then
      echo "the Unreleased section of the changelog has entries"
      exit 1
    fi
    writeResult true "requested version"
  elif tagExists; then
    writeResult false "tag v$RELEASE_VERSION already exists"
  elif unreleasedHasEntries; then
    writeResult false "the Unreleased section of the changelog has entries"
  else
    writeResult true "latest version of the changelog"
  fi
}

# Runs the requested validation of the release version
function main() {
  case "${1:-}" in
    branch) branch ;;
    version-format) versionFormat ;;
    tag) tag ;;
    release-notes) releaseNotes ;;
    release) release ;;
    *)
      echo "missing or unknown argument, it must be one of the following: branch, version-format, tag, release-notes, release" >&2
      exit 2
      ;;
  esac
}

main "$@"
