#!/usr/bin/env bash
set -euo pipefail

# Ensure script runs from its own directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

echo "Stopping and removing any test container..."
docker rm -f openproject-test >/dev/null 2>&1 || true

if [ -d "openproject-docker-compose" ]; then
  echo "Tearing down OpenProject production stack (with volumes)..."
  cd openproject-docker-compose
  docker compose down --volumes --remove-orphans
  cd "$SCRIPT_DIR"
  echo "Removing openproject-docker-compose directory..."
  rm -rf openproject-docker-compose
else
  echo "No openproject-docker-compose directory found; skipping production teardown."
fi

echo "Teardown complete. Only the OpenProject resources were removed." 