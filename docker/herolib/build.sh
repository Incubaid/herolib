#!/bin/bash -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Copy installation files
cp ../../scripts/install_v.sh ./scripts/install_v.sh
cp ../../scripts/install_herolib.vsh ./scripts/install_herolib.vsh

# Docker image and container names
DOCKER_IMAGE_NAME="herolib"
DEBUG_CONTAINER_NAME="herolib"

function cleanup {
  if docker ps -aq -f name="$DEBUG_CONTAINER_NAME" &>/dev/null; then
    echo "Cleaning up leftover debug container..."
    docker rm -f "$DEBUG_CONTAINER_NAME" &>/dev/null || true
  fi
}
trap cleanup EXIT

# Attempt to build the Docker image
BUILD_LOG=$(mktemp)
set +e
docker build --name herolib --progress=plain -t "$DOCKER_IMAGE_NAME" . 
BUILD_EXIT_CODE=$?
set -e

# Handle build failure
if [ $BUILD_EXIT_CODE -ne 0 ]; then
  echo -e "\\n[ERROR] Docker build failed.\n"
  echo -e "remove the part which didn't build in the Dockerfile, the run again and to debug do:"
  echo docker run --name herolib -it --entrypoint=/bin/bash "herolib"
  exit $BUILD_EXIT_CODE
else
  echo -e "\\n[INFO] Docker build completed successfully."
fi


