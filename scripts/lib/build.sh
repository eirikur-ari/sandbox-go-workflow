# shellcheck shell=bash
# Functions of the build tasks, which are the tasks build and build-all.
# Sourced by the tasks, it sets no shell options and runs nothing.

# shellcheck source-path=SCRIPTDIR source=platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

# Compiles a static binary for the given platform at the given output path
function gobuild() {
  local goos="$1" goarch="$2" output="$3"
 # local version_var=github.com/github-workflow-sandbox/samples/golang/dummy/internal/composition.releaseVersion

  CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" GOFLAGS=-mod=readonly \
    go build -trimpath -buildvcs=false -ldflags "-s -w" -o "$output" ./cmd
}

# Builds the binary for the given target
function buildTarget() {
  local target="$1"

  echo "Building $target"
  gobuild "${target%/*}" "${target#*/}" "$(binaryPath "$target")"
}

# Builds the binary for the platform the script runs on
function buildHost() {
  local target

  target=$(hostTarget) || return
  buildTarget "$target"
}

# Builds the binary for every target
function buildAll() {
  local target

  for target in "${TARGETS[@]}"; do
    buildTarget "$target"
  done
}
