# Makefile for api-cortes
# Build and push to Docker Hub

# Variables
IMAGE_NAME := n8n-ffmpeg
REGISTRY := docker.io
DOCKER_USERNAME := $(shell git config user.name | tr '[:upper:]' '[:lower:]')
FULL_IMAGE_NAME := $(REGISTRY)/$(DOCKER_USERNAME)/$(IMAGE_NAME)
VERSION := $(shell git rev-parse --short HEAD)
LATEST_TAG := latest

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build         - Build Docker image"
	@echo "  tag           - Tag image for Docker Hub"
	@echo "  push          - Push image to Docker Hub"
	@echo "  build-push    - Build, tag and push image"
	@echo "  login         - Login to Docker Hub"
	@echo "  clean         - Remove local images"
	@echo ""
	@echo "Environment variables:"
	@echo "  DOCKER_USERNAME - Docker Hub username (defaults to git username)"
	@echo "  DOCKER_PASSWORD - Docker Hub password (required for push)"

# Build the Docker image
.PHONY: build
build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker build -t $(IMAGE_NAME):$(LATEST_TAG) .

# Tag image for Docker Hub
.PHONY: tag
tag: build
	@echo "Tagging image for Docker Hub..."
	docker tag $(IMAGE_NAME):$(VERSION) $(FULL_IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME):$(LATEST_TAG) $(FULL_IMAGE_NAME):$(LATEST_TAG)

# Login to Docker Hub
.PHONY: login
login:
	@echo "Logging in to Docker Hub..."
	@if [ -z "$(DOCKER_PASSWORD)" ]; then \
		echo "Error: DOCKER_PASSWORD environment variable is required"; \
		echo "You can also run: docker login"; \
		echo "Then run: export DOCKER_PASSWORD=your_password"; \
		exit 1; \
	fi
	@echo $(DOCKER_PASSWORD) | docker login $(REGISTRY) -u $(DOCKER_USERNAME) --password-stdin

# Push image to Docker Hub
.PHONY: push
push: tag
	@echo "Pushing image to Docker Hub..."
	docker push $(FULL_IMAGE_NAME):$(VERSION)
	docker push $(FULL_IMAGE_NAME):$(LATEST_TAG)

# Build, tag and push in one command
.PHONY: build-push
build-push: push
	@echo "Build and push completed successfully!"
	@echo "Image available at: $(FULL_IMAGE_NAME):$(LATEST_TAG)"

# Clean up local images
.PHONY: clean
clean:
	@echo "Cleaning up local images..."
	-docker rmi $(IMAGE_NAME):$(VERSION)
	-docker rmi $(IMAGE_NAME):$(LATEST_TAG)
	-docker rmi $(FULL_IMAGE_NAME):$(VERSION)
	-docker rmi $(FULL_IMAGE_NAME):$(LATEST_TAG)

# Development helpers
.PHONY: run
run:
	@echo "Running container locally..."
	docker run -d -p 8000:8000 -v $(PWD)/storage:/app/storage $(IMAGE_NAME):$(LATEST_TAG)

.PHONY: dev
dev:
	@echo "Starting development server..."
	uvicorn main:app --reload --host 0.0.0.0 --port 8000