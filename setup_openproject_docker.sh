#!/usr/bin/env bash
# Ensure the script runs from its own directory (workspace root)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
set -euo pipefail
export DOCKER_DEFAULT_PLATFORM=linux/amd64

# This script bootstraps OpenProject using the official production Docker Compose setup
# It clones the stable/16 branch, copies .env, builds buildable services, and starts the stack.

# Variables
DC_REPO_URL="https://github.com/opf/openproject-docker-compose.git"
DC_DIR="openproject-docker-compose"
BRANCH="stable/16"
DEPTH=1
# Note: The compose filename is standard docker-compose.yml
COMPOSE_FILE="docker-compose.yml"

# Step 1: Clone or update the docker-compose repo (shallow, stable/16)
if [ ! -d "$DC_DIR" ]; then
  echo "Cloning openproject-docker-compose branch $BRANCH (shallow depth $DEPTH)..."
  git clone --depth $DEPTH --branch "$BRANCH" "$DC_REPO_URL" "$DC_DIR"
else
  echo "Updating openproject-docker-compose to latest $BRANCH..."
  cd "$DC_DIR"
  git fetch --depth $DEPTH origin "$BRANCH"
  git reset --hard origin/"$BRANCH"
  cd ..
fi

# Step 2: Run Docker Compose from that directory
cd "$DC_DIR"

# Stop and remove any existing containers and volumes for a fresh start
echo "Stopping existing stack and removing volumes..."
docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
 
# Step 2: Copy example .env if missing
if [ ! -f ".env" ]; then
  echo "Copying .env.example to .env..."
  cp .env.example .env
else
  echo ".env already exists"
fi

# Force TAG to 16.1.1-slim for version 16.1.1
echo "Setting TAG to 16.1.1-slim in .env..."
sed -i '' 's/^TAG=.*/TAG=16.1.1-slim/' .env

# Remove PGDATA and OPDATA overrides so named volumes are used
echo "Removing PGDATA and OPDATA overrides for named volumes..."
sed -i '' '/^PGDATA=/d' .env
sed -i '' '/^OPDATA=/d' .env
 
echo "Pulling Docker images (production)..."
# Pull only non-buildable images; buildable ones will be built next
docker compose pull --ignore-buildable
 
echo "Starting OpenProject production stack..."
docker compose up -d --build --pull always --remove-orphans
 
echo "Current container status:"
docker compose ps
 
# Step 4: Verify that all non-seeder services are running for 10 seconds
echo "Verifying all non-seeder services are running for 10 seconds..."
# Exclude the one-off 'seeder' service from stability check
SERVICES=$(docker compose config --services | grep -v '^seeder$')
TOTAL=$(echo "$SERVICES" | wc -l)
for i in $(seq 1 5); do
  RUNNING=$(docker compose ps --services --filter "status=running" | grep -v '^seeder$' | wc -l)
  if [ "$RUNNING" -eq "$TOTAL" ]; then
    echo "All $TOTAL services running."
    break
  fi
  echo "Only $RUNNING/$TOTAL services running, retrying in 2s..."
  sleep 2
  if [ "$i" -eq 5 ]; then
    echo "Error: Some services failed to start properly:";
    docker compose ps
    exit 1
  fi
done
# Primary stack is stable; now verify web health endpoint
echo "OpenProject production stack is stable. Verifying web health endpoint..."

# Step 5: Wait for HTTP health endpoint to be available
HEALTH_URL="http://localhost:8080/health_checks/default"
LOGIN_URL="http://localhost:8080/login"
echo "Health URL: $HEALTH_URL"
echo "Login URL: $LOGIN_URL"
for i in $(seq 1 30); do
  if curl -fs "$HEALTH_URL" >/dev/null; then
    echo "Web health endpoint is OK."
    break
  fi
  echo "Health check not yet OK, retrying in 2s..."
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "Error: Web health endpoint still not responding.";
    curl -fs "$HEALTH_URL" || true
    docker compose ps
    exit 1
  fi
done
echo "Setup complete: OpenProject available at $LOGIN_URL" 