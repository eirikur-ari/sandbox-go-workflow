# shellcheck shell=bash
# Functions of the platform conventions that the build, package and acceptance tasks share.
# A platform is a target, written <goos>/<goarch> as in TARGETS, and the binary of a target is BIN_DIR/<goos>_<goarch>/BINARY_NAME.
# Sourced by the tasks, it sets no shell options and runs nothing.

# shellcheck source-path=SCRIPTDIR source=config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Prints the target of the platform the script runs on
function hostTarget() {
  local goos goarch

  goos=$(go env GOOS) || return
  goarch=$(go env GOARCH) || return
  echo "$goos/$goarch"
}

# Prints the path of the binary of the given target
function binaryPath() {
  local target="$1"

  echo "$BIN_DIR/${target%/*}_${target#*/}/$BINARY_NAME"
}
