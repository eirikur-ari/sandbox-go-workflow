# shellcheck shell=bash
# Shared setup for the bats tests of the scripts in scripts/.
# Each test runs in a temp workspace, set as WORKSPACE_FOLDER, with fake go, docker and devcontainer executables first on PATH.
# The fakes append every call to go.log, docker.log and devcontainer.log in TEST_TMP, and are driven by environment variables set per test:
#   FAKE_GOOS, FAKE_GOARCH   what go env GOOS and go env GOARCH print, default linux and amd64
#   GO_ENV_FAIL              when non-empty, go env exits 1
#   GO_BUILD_FAIL            when non-empty, go build exits 1
#   GO_TEST_FAIL             when non-empty, go test exits 1
#   DOCKER_PS_IDS            what docker ps prints, default nothing
#   DOCKER_INSPECT_OUT       what docker inspect prints, default nothing
#   DOCKER_EXEC_DRYRUN       when non-empty, docker exec only logs and drains stdin, otherwise it runs the command it is given locally
# go build creates the file given with -o, containing "binary <GOOS>/<GOARCH>".

SCRIPTS="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Creates the temp workspace and the fake executables before each test
function setup() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
  mkdir -p "$TEST_TMP/bin" "$TEST_TMP/ws"
  export PATH="$TEST_TMP/bin:$PATH"

  # Start from the defaults of lib/config.sh whatever the environment of the caller
  unset BINARY_NAME BUILD_DIR BIN_DIR DIST_DIR PACKAGE_DIR ACCEPTANCE_DIR DUMMY_BINARY RELEASE_VERSION DC_SHELL
  export WORKSPACE_FOLDER="$TEST_TMP/ws"

  cat > "$TEST_TMP/bin/go" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  env)
    [[ -z "${GO_ENV_FAIL:-}" ]] || exit 1
    case "$2" in
      GOOS) echo "${FAKE_GOOS:-linux}" ;;
      GOARCH) echo "${FAKE_GOARCH:-amd64}" ;;
    esac
    ;;
  build)
    [[ -z "${GO_BUILD_FAIL:-}" ]] || exit 1
    echo "build GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=$CGO_ENABLED GOFLAGS=$GOFLAGS cwd=$PWD args=$*" >> "$TEST_TMP/go.log"
    args=("$@")
    for i in "${!args[@]}"; do
      [[ "${args[i]}" != -o ]] || out="${args[i+1]}"
    done
    mkdir -p "$(dirname "$out")"
    echo "binary $GOOS/$GOARCH" > "$out"
    chmod +x "$out"
    ;;
  test)
    [[ -z "${GO_TEST_FAIL:-}" ]] || exit 1
    echo "test DUMMY_BINARY=${DUMMY_BINARY:-} cwd=$PWD args=$*" >> "$TEST_TMP/go.log"
    ;;
esac
EOF
  cat > "$TEST_TMP/bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "docker $*" >> "$TEST_TMP/docker.log"
case "$1" in
  ps) [[ -z "${DOCKER_PS_IDS:-}" ]] || printf '%s\n' "$DOCKER_PS_IDS" ;;
  inspect) printf '%s\n' "${DOCKER_INSPECT_OUT:-}" ;;
  exec)
    shift
    if [[ -n "${DOCKER_EXEC_DRYRUN:-}" ]]; then
      [[ "$1" != -i ]] || cat > /dev/null
      exit 0
    fi
    [[ "$1" != -i ]] || shift
    shift # the container id
    exec "$@"
    ;;
esac
EOF
  cat > "$TEST_TMP/bin/devcontainer" <<'EOF'
#!/usr/bin/env bash
echo "devcontainer $*" >> "$TEST_TMP/devcontainer.log"
EOF
  chmod +x "$TEST_TMP"/bin/*

  # The scripts move to the workspace themselves, so start somewhere else to show it
  cd "$TEST_TMP" || return 1
}

# Removes the temp workspace after each test
function teardown() {
  rm -rf "$TEST_TMP"
}

# Platforms of TARGETS in lib/config.sh
# shellcheck disable=SC2034 # used by the tests that load this file
TARGET_PLATFORMS=(linux/amd64 linux/arm64 darwin/amd64 darwin/arm64)

# Runs the given script of scripts/ with the given arguments, capturing status and output (stdout and stderr) in bats' $status and $output
function run_script() {
  local script="$1"
  shift
  run bash "$SCRIPTS/$script" "$@"
}

# Creates a gzipped tar archive at the given path holding one file named after the second argument
function make_archive() {
  local archive="$1" file="$2" content
  content="$(mktemp -d)"
  echo "$file" > "$content/$file"
  mkdir -p "$(dirname "$archive")"
  tar -czf "$archive" -C "$content" .
  rm -rf "$content"
}
