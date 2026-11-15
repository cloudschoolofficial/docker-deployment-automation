#!/bin/bash

# =====================================
# Docker Container Deployment Automation
# =====================================

set -Eeuo pipefail

# Configuration
IMAGE_NAME="my-web-app"
IMAGE_TAG="latest"
CONTAINER_NAME="my-web-container"

HOST_PORT=8080
CONTAINER_PORT=80

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a deployment.log
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Step 1: Check Docker installation
log "Checking Docker installation..."

command -v docker >/dev/null 2>&1 || \
    error_exit "Docker is not installed."

# Step 2: Check Docker access
log "Checking Docker access..."

docker info >/dev/null 2>&1 || \
    error_exit "Cannot access Docker daemon."

# Step 3: Validate project files
log "Validating project files..."

[[ -f "$PROJECT_DIR/Dockerfile" ]] || \
    error_exit "Dockerfile not found."

[[ -f "$PROJECT_DIR/index.html" ]] || \
    error_exit "index.html not found."

# Step 4: Build Docker image
log "Building Docker image..."

docker build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$PROJECT_DIR" || \
    error_exit "Docker image build failed."

# Step 5: Check existing container
log "Checking existing container..."

if docker container inspect "$CONTAINER_NAME" \
    >/dev/null 2>&1; then

    log "Existing container found."

    docker stop "$CONTAINER_NAME" || \
        error_exit "Failed to stop existing container."

    docker rm "$CONTAINER_NAME" || \
        error_exit "Failed to remove existing container."

else
    log "No existing container found."
fi

# Step 6: Deploy new container
log "Deploying new container..."

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}:${IMAGE_TAG}" || \
    error_exit "Container deployment failed."

# Step 7: Verify deployment
log "Verifying deployment..."

if docker container inspect "$CONTAINER_NAME" \
    --format '{{.State.Running}}' | grep -qx true; then

    log "SUCCESS: Container deployed successfully!"

    echo "--------------------------------"
    echo "Container: $CONTAINER_NAME"
    echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "Application: http://localhost:${HOST_PORT}"
    echo "--------------------------------"

else
    error_exit "Container is not running."
fi

log "Deployment process completed."
