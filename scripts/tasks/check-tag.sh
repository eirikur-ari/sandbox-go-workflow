#!/usr/bin/env bash
# Fails when the tag of RELEASE_VERSION already exists, so that a version is never released twice.
# Requires RELEASE_VERSION in the environment. It reads the tags of the git repository, so they must have been fetched.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

# Succeeds when the release tag exists, fails when it does not, and exits when git fails for any other reason
function tagExists() {
  local status=0

  git show-ref --verify --quiet "refs/tags/v$RELEASE_VERSION" || status=$?
  case "$status" in
    0) return 0 ;;
    1) return 1 ;;
    *)
      echo "git could not look up the tag v$RELEASE_VERSION" >&2
      exit 1
      ;;
  esac
}

# Fails when the release tag already exists
function verifyTag() {
  requireEnv RELEASE_VERSION
  if tagExists; then
    echo "tag v$RELEASE_VERSION already exists"
    exit 1
  fi
}

# Checks that the release tag does not exist
function main() {
  verifyTag
}

main
