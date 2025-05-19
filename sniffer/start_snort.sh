#!/bin/bash
# Script to build and start the Snort 3 Docker container.
# This script should be run with sudo or by a user in the docker group.

# Navigate to the directory containing docker-compose.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Building Snort Docker image..."
if docker-compose build; then
    echo "Snort Docker image built successfully."
else
    echo "Error: Failed to build Snort Docker image." >&2
    exit 1
fi

echo "Starting Snort container in detached mode..."
if docker-compose up -d; then
    echo "Snort container started successfully."
    echo "To view logs, use: docker-compose logs -f snort"
    echo "To stop the container, use: docker-compose down"
else
    echo "Error: Failed to start Snort container." >&2
    exit 1
fi

exit 0
