#!/bin/bash
# Script to build and start the Snort 3 Docker container.
# This script should be run with sudo or by a user in the docker group.

# Navigate to the directory containing docker-compose.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Cleaning up existing Docker resources..."
# Stop and remove containers, networks, and volumes defined in docker-compose.yml
docker-compose down --volumes
# Remove all stopped containers
docker container prune -f
# Remove all unused local volumes
docker volume prune -f
echo "Cleanup complete."

# Ensure local directories for Docker volumes exist
mkdir -p ./snort_config
mkdir -p ./rules
mkdir -p ./snort_logs

echo "Building Snort Docker image..."
if docker-compose build; then
    echo "Snort Docker image built successfully."
else
    echo "Error: Failed to build Snort Docker image." >&2
    exit 1
fi

echo "Starting Snort container..."
echo "To exit the container, use Ctrl+C."
if docker-compose up; then
    echo "Snort container exited successfully."
else
    echo "Error: Failed to start Snort container." >&2
    exit 1
fi

exit 0
