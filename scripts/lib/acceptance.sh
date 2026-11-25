# shellcheck shell=bash
# Functions of the acceptance tasks, which are the tasks acceptance-extract and acceptance-test.
# The binary under test is the one of the host platform in BIN_DIR/<goos>_<goarch>/, which is the one that build wrote or that acceptance-extract unpacked.
# APP_BINARY is the binary the tests run against instead, when it is set.
# Sourced by the tasks, it sets no shell options and runs nothing.

# shellcheck source-path=SCRIPTDIR source=platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

# Prints the path of the only archive in DIST_DIR for the platform the script runs on, and fails when there is not exactly one
function archivePath() {
  local target archives

  target=$(hostTarget) || return
  archives=$(find "$DIST_DIR" -maxdepth 1 -name "${BINARY_NAME}_*_${target%/*}_${target#*/}.tar.gz")
  if [[ -z "$archives" || "$archives" == *$'\n'* ]]; then
    echo "expected exactly one $target archive in $DIST_DIR, found: ${archives:-none}" >&2
    exit 1
  fi
  echo "$archives"
}

# Extracts the binary from the archive of this platform into BIN_DIR/<goos>_<goarch>/, replacing the one that is there
function extract() {
  local archive target directory

  archive=$(archivePath)
  target=$(hostTarget) || return
  directory=$(dirname "$(binaryPath "$target")")
  mkdir -p "$directory"
  tar -xzf "$archive" -C "$directory" "$BINARY_NAME"
}

# Runs the acceptance tests against the binary, failing when it does not exist
function run() {
  local binary="${APP_BINARY:-}" target

  if [[ -z "$binary" ]]; then
    target=$(hostTarget) || return
    binary="$WORKSPACE_FOLDER/$(binaryPath "$target")"
  fi

  if [[ ! -x "$binary" ]]; then
    echo "the binary to test does not exist: $binary" >&2
    exit 1
  fi
  APP_BINARY="$binary" go test -v -tags acceptance -run TestAcceptance -count=1 ./...
}
