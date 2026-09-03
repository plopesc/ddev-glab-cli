#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=plopesc/ddev-glab-cli

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  LATEST_VERSION=$(curl -sL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest" | grep -o '"tag_name":"[^"]*"' | sed 's/"tag_name":"v\([^"]*\)"/\1/')
  run ddev exec "glab --version"
  assert_success
  assert_output --partial "${LATEST_VERSION}"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "install with custom version" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with custom GLAB_VERSION in $(pwd)" >&3
  printf "services:\n  web:\n    build:\n      args:\n        GLAB_VERSION: \"1.80.0\"\n" > .ddev/docker-compose.glab-cli.yaml
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  run ddev exec "glab --version"
  assert_success
  assert_output --partial "1.80.0"
}

@test "seeds host glab config into the container" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} and check the glab config seed in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success

  # The pre-start hook creates the host-side files the mount depends on.
  assert_file_exist "${HOME}/.config/glab-cli/config.yml"
  assert_file_exist "${HOME}/.config/glab-cli/aliases.yml"

  # The seed must land on a fixed container path. Using ${HOME} as the mount
  # target would break on macOS, where the host home (/Users/<user>) differs
  # from the container home (/home/<user>).
  run ddev exec "test -f /mnt/ddev-glab-cli-seed/config.yml"
  assert_success
  run ddev exec "test -f /mnt/ddev-glab-cli-seed/aliases.yml"
  assert_success

  # And the post-start hook must have copied it where glab actually reads it.
  run ddev exec 'test -f "${HOME}/.config/glab-cli/config.yml"'
  assert_success
  run ddev exec 'cmp -s /mnt/ddev-glab-cli-seed/config.yml "${HOME}/.config/glab-cli/config.yml"'
  assert_success
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
