# Makefile for api-cortes
# Build and push to GitHub Container Registry

# Variables
IMAGE_NAME := n8n-ffmpeg
REGISTRY := docker.io 
GITHUB_USERNAME := $(shell git config user.name | tr '[:upper:]' '[:lower:]')
FULL_IMAGE_NAME := $(REGISTRY)/$(GITHUB_USERNAME)/$(IMAGE_NAME)
VERSION := $(shell git rev-parse --short HEAD)
LATEST_TAG := latest

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build         - Build Docker image"
	@echo "  tag           - Tag image for GitHub Container Registry"
	@echo "  push          - Push image to GitHub Container Registry"
	@echo "  build-push    - Build, tag and push image"
	@echo "  login         - Login to GitHub Container Registry"
	@echo "  clean         - Remove local images"
	@echo ""
	@echo "Environment variables:"
	@echo "  GITHUB_TOKEN  - GitHub personal access token (required for push)"

# Build the Docker image
.PHONY: build
build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker build -t $(IMAGE_NAME):$(LATEST_TAG) .

# Tag image for GitHub Container Registry
.PHONY: tag
tag: build
	@echo "Tagging image for GitHub Container Registry..."
	docker tag $(IMAGE_NAME):$(VERSION) $(FULL_IMAGE_NAME):$(VERSION)
	docker tag $(IMAGE_NAME):$(LATEST_TAG) $(FULL_IMAGE_NAME):$(LATEST_TAG)

# Login to GitHub Container Registry
.PHONY: login
login:
	@echo "Logging in to GitHub Container Registry..."
	@if [ -z "$(GITHUB_TOKEN)" ]; then \
		echo "Error: GITHUB_TOKEN environment variable is required"; \
		echo "Create a personal access token at: https://github.com/settings/tokens"; \
		echo "Grant 'write:packages' permission"; \
		echo "Then run: export GITHUB_TOKEN=your_token"; \
		exit 1; \
	fi
	@echo $(GITHUB_TOKEN) | docker login $(REGISTRY) -u $(GITHUB_USERNAME) --password-stdin

# Push image to GitHub Container Registry
.PHONY: push
push: tag login
	@echo "Pushing image to GitHub Container Registry..."
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