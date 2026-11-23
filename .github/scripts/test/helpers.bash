# shellcheck shell=bash
# Shared setup for validate-release.bats.
# Runs the script in a temp working directory with fake gh, git and make executables first on PATH, and fake changelog scripts under scripts/.
# The fakes are driven by environment variables, set per test:
#   GH_MODE                   exists (default), missing (HTTP 404) or error (HTTP 500)
#   GIT_TAGS                  newline separated release tags merged into the branch, which git tag lists newest first by version, default none
#   GIT_SHALLOW               what git rev-parse --is-shallow-repository prints, default false
#   GIT_FAIL                  when non-empty, git exits 128
#   MAKE_FAIL                 when non-empty, make exits 1
#   CHANGELOG_VERSION         version printed by changelog-version.sh, default 1.2.3
#   CHANGELOG_VERSION_FAIL    when non-empty, changelog-version.sh exits 1
#   CHANGELOG_UNRELEASED      text printed by changelog-unreleased.sh, default empty
#   CHANGELOG_UNRELEASED_FAIL when non-empty, changelog-unreleased.sh exits 1

SCRIPT="$BATS_TEST_DIRNAME/../validate-release.sh"

# Creates the temp working directory and the fake executables before each test
function setup() {
  TEST_TMP="$(mktemp -d)"
  mkdir -p "$TEST_TMP/bin" "$TEST_TMP/work/scripts"
  export PATH="$TEST_TMP/bin:$PATH"
  on_branch fakebranch
  export GITHUB_OUTPUT="$TEST_TMP/output"
  export GITHUB_STEP_SUMMARY="$TEST_TMP/summary"
  : > "$GITHUB_OUTPUT"
  : > "$GITHUB_STEP_SUMMARY"

  cat > "$TEST_TMP/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "${GH_MODE:-exists}" in
  exists) echo '{"ref":"refs/tags/vX"}' ;;
  missing) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  error) echo "gh: Server Error (HTTP 500)" >&2; exit 1 ;;
esac
EOF
  cat > "$TEST_TMP/bin/git" <<'EOF'
#!/usr/bin/env bash
[[ -z "${GIT_FAIL:-}" ]] || { echo "fatal: git failed" >&2; exit 128; }
case "$1" in
  rev-parse) echo "${GIT_SHALLOW:-false}" ;;
  tag) [[ -z "${GIT_TAGS:-}" ]] || printf '%s\n' "$GIT_TAGS" | sort -rV ;;
esac
EOF
  cat > "$TEST_TMP/bin/make" <<'EOF'
#!/usr/bin/env bash
[[ -z "${MAKE_FAIL:-}" ]] || { echo "make: no release notes" >&2; exit 1; }
echo "release notes"
EOF
  cat > "$TEST_TMP/work/scripts/changelog-version.sh" <<'EOF'
#!/usr/bin/env bash
[[ -z "${CHANGELOG_VERSION_FAIL:-}" ]] || { echo "no versions in changelog" >&2; exit 1; }
echo "${CHANGELOG_VERSION:-1.2.3}"
EOF
  cat > "$TEST_TMP/work/scripts/changelog-unreleased.sh" <<'EOF'
#!/usr/bin/env bash
[[ -z "${CHANGELOG_UNRELEASED_FAIL:-}" ]] || { echo "no Unreleased section" >&2; exit 1; }
printf '%s' "${CHANGELOG_UNRELEASED:-}"
EOF
  chmod +x "$TEST_TMP"/bin/* "$TEST_TMP"/work/scripts/*.sh

  cd "$TEST_TMP/work" || return 1
}

# Removes the temp working directory after each test
function teardown() {
  rm -rf "$TEST_TMP"
}

# Runs the script with the given subcommand, capturing status and output (stdout and stderr) in bats' $status and $output
function run_script() {
  run bash "$SCRIPT" "$@"
}

# Runs as the given branch, setting GITHUB_REF_NAME and GITHUB_REF the way GitHub Actions does
function on_branch() {
  export GITHUB_REF_NAME="$1"
  export GITHUB_REF="refs/heads/$1"
}

# Sets the environment the release subcommand requires, on the master branch
function release_env() {
  on_branch master
  export GITHUB_REPOSITORY=owner/repo
  export GH_TOKEN=token
}
