# CLAUDE.md

## Project Overview

**ddev-glab-cli** is a DDEV add-on that installs the [GitLab CLI (`glab`)](https://gitlab.com/gitlab-org/cli) into the DDEV web container.

- **DDEV version requirement**: >= v1.24.3
- **Repository**: `plopesc/ddev-glab-cli`

## Architecture

- `install.yaml` — DDEV add-on manifest; declares project files, DDEV version constraint, and post-install messaging
- `web-build/Dockerfile.glab-cli` — Downloads and installs `glab` at build time; defaults to the latest available version by querying the GitLab API, but accepts a pinned version via the `GLAB_VERSION` build arg
- `.devcontainer/` — Local development container for working on the add-on itself
- `tests/test.bats` — BATS integration tests
- `.github/workflows/tests.yml` — CI using `ddev/github-action-add-on-test@v2`, matrix: DDEV `stable` + `HEAD`

## Customizing the glab Version

By default the Dockerfile resolves and installs the latest `glab` release. To pin a specific version, create `.ddev/docker-compose.glab-cli.yaml` in the project:

```yaml
services:
  web:
    build:
      args:
        GLAB_VERSION: "1.80.0"
```

Then run `ddev restart` to rebuild with the pinned version.

## Testing

Tests use [BATS](https://bats-core.readthedocs.io/) with bats-assert, bats-file, and bats-support libraries.

```bash
# Run all tests
bats ./tests/test.bats

# Exclude release tests (for local development)
bats ./tests/test.bats --filter-tags '!release'

# Debug mode
bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure
```

Tests spin up a temporary DDEV project (`test-ddev-glab-cli`), install the add-on, and verify:
1. `glab --version` succeeds and reports the expected version
2. A custom `GLAB_VERSION` passed via `docker-compose.glab-cli.yaml` is correctly installed

The `install from release` test (tagged `@release`) installs from GitHub releases; skip it locally with `--filter-tags '!release'`.

## Development Notes

- **BATS tests must be run on the host machine**, not inside the devcontainer — they require DDEV, which manages Docker containers and cannot run inside a container itself
- Commits use conventional commit format (e.g., `feat:`, `fix:`)
- CI runs on PRs, pushes to `main`, and daily at 08:25 UTC
- `.gitattributes` excludes tests, `.github/`, and docs from release archives
