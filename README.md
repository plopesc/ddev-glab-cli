[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/plopesc/ddev-glab-cli/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/plopesc/ddev-glab-cli/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/plopesc/ddev-glab-cli)](https://github.com/plopesc/ddev-glab-cli/commits)
[![release](https://img.shields.io/github/v/release/plopesc/ddev-glab-cli)](https://github.com/plopesc/ddev-glab-cli/releases/latest)

# DDEV Glab Cli

## Overview

This add-on integrates Glab Cli into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get plopesc/ddev-glab-cli
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Glab Cli |
| `ddev logs -s glab-cli` | Check Glab Cli logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.glab-cli --glab-cli-docker-image="ddev/ddev-utilities:latest"
ddev add-on get plopesc/ddev-glab-cli
ddev restart
```

Make sure to commit the `.ddev/.env.glab-cli` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `GLAB_CLI_DOCKER_IMAGE` | `--glab-cli-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@plopesc](https://github.com/plopesc)**
