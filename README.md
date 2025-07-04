# openproject-tools

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/Konard/openproject-tools)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?repo=Konard/openproject-tools)

Tools to install, test, and uninstall OpenProject via Docker.

## Scripts

- `setup_openproject_docker.sh`: Idempotent bootstrap of the OpenProject production stack
- `test_openproject_allinone.sh`: Automated health check for the 16.1.1 all-in-one Docker image
- `teardown_openproject.sh`: Clean teardown of containers, volumes, and compose directory

## Usage

1. BOOTSTRAP: `./setup_openproject_docker.sh`
2. TEST: `./test_openproject_allinone.sh`
3. TEARDOWN: `./teardown_openproject.sh`

## License

This project is licensed under the Unlicense.
