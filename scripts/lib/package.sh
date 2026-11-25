# shellcheck shell=bash
# Functions of the package tasks, which are the tasks package and package-all.
# The archives are named for RELEASE_VERSION, or dev when that is not set, and are written to DIST_DIR.
# Sourced by the tasks, it sets no shell options and runs nothing.

# shellcheck source-path=SCRIPTDIR source=platform.sh
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

# Moves to the workspace and creates the output directory
function setup() {
  cd "$WORKSPACE_FOLDER" || return 1
  mkdir -p "$DIST_DIR"
}

# Prints the path of the archive for the given version, os and architecture
function archivePath() {
  local version="$1" goos="$2" goarch="$3"
  echo "$WORKSPACE_FOLDER/$DIST_DIR/${BINARY_NAME}_${version}_${goos}_${goarch}.tar.gz"
}

# Gathers the given binary and the files to ship with it in the package directory, replacing the binary of the previous package
function stagePackage() {
  local binary="$1"

  mkdir -p "$PACKAGE_DIR/docs"
  cp "$binary" LICENSE README.md CHANGELOG.md "$PACKAGE_DIR/"
  #cp -R docs/images "$PACKAGE_DIR/docs/"
}

# Archives the content of the package directory into the given archive path
function createArchive() {
  local archive="$1"

  (
    cd "$PACKAGE_DIR" || exit 1
    # The tar of macOS adds its extended attributes to the archive as extra ._ files unless COPYFILE_DISABLE is set
    if [[ "$(uname)" == "Darwin" ]]; then
      COPYFILE_DISABLE=1 tar --no-xattrs --exclude .DS_Store -czf "$archive" -- *
    else
      tar -czf "$archive" -- *
    fi
  )
}

# Packages the binary of the given target and its accompanying files into the archive of the given version
function packageTarget() {
  local version="$1" target="$2"

  stagePackage "$(binaryPath "$target")"
  createArchive "$(archivePath "$version" "${target%/*}" "${target#*/}")"
}
