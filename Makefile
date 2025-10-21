# Makefile for STM32 Docker Development Environment# Makefile for STM32 Docker Development Environment



.PHONY: help build run clean test lint format install-tools devcontainer setup-hooks.PHONY: help build run clean test lint format install-tools devcontainer pre-commit



# Default target# Default target

help:help:

	@echo "STM32 Docker Development Environment"	@echo "STM32 Docker Development Environment"

	@echo "=================================="	@echo "=================================="

	@echo ""	@echo ""

	@echo "Available targets:"	@echo "Available targets:"

	@echo "  build         - Build the Docker image"	@echo "  build         - Build the Docker image"

	@echo "  run           - Run the container interactively"	@echo "  run           - Run the container interactively"

	@echo "  clean         - Remove Docker images and containers"	@echo "  clean         - Remove Docker images and containers"

	@echo "  test          - Test the Docker image"	@echo "  test          - Test the Docker image"

	@echo "  lint          - Run code quality checks via Git hooks"	@echo "  lint          - Run code quality checks via Git hooks"

	@echo "  format        - Format code via Git hooks"	@echo "  format        - Format code via Git hooks"

	@echo "  install-tools - Install development tools in running container"	@echo "  install-tools - Install development tools in running container"

	@echo "  devcontainer  - Setup VS Code DevContainer"	@echo "  devcontainer  - Setup VS Code DevContainer"

	@echo "  setup-hooks   - Setup Git hooks for code quality"	@echo "  setup-hooks   - Setup Git hooks for code quality"

	@echo "  hooks-status  - Show Git hooks status"	@echo "  hooks-status  - Show Git hooks status"

	@echo ""	@echo ""

	@echo "Configuration:"	@echo "Configuration:"

	@echo "  IMAGE_NAME    = $(IMAGE_NAME)"	@echo "  IMAGE_NAME    = $(IMAGE_NAME)"

	@echo "  CONTAINER_NAME= $(CONTAINER_NAME)"	@echo "  CONTAINER_NAME= $(CONTAINER_NAME)"

	@echo "  VERSION       = $(VERSION)"	@echo "  VERSION       = $(VERSION)"



# Configuration# Configuration

IMAGE_NAME := stm32-devIMAGE_NAME := stm32-dev

CONTAINER_NAME := stm32-dev-containerCONTAINER_NAME := stm32-dev-container

VERSION := latestVERSION := latest

DOCKERFILE := DockerfileDOCKERFILE := Dockerfile



# Build the Docker image# Build the Docker image

build:build:

	@echo "Building Docker image: $(IMAGE_NAME):$(VERSION)"	@echo "Building Docker image: $(IMAGE_NAME):$(VERSION)"

	docker build -t $(IMAGE_NAME):$(VERSION) .	docker build -t $(IMAGE_NAME):$(VERSION) .



# Run the container interactively# Run the container interactively

run:run:

	@echo "Running container: $(CONTAINER_NAME)"	@echo "Running container: $(CONTAINER_NAME)"

	docker run -it --rm \	docker run -it --rm \

		--name $(CONTAINER_NAME) \		--name $(CONTAINER_NAME) \

		--privileged \		--privileged \

		-v /dev:/dev \		-v /dev:/dev \

		-v $(PWD):/workspace \		-v $(PWD):/workspace \

		-w /workspace \		-w /workspace \

		-p 3333:3333 \		-p 3333:3333 \

		-p 4444:4444 \		-p 4444:4444 \

		$(IMAGE_NAME):$(VERSION) \		$(IMAGE_NAME):$(VERSION) \

		/bin/bash		/bin/bash



# Run container in background# Run container in background

run-background:run-background:

	@echo "Starting container in background: $(CONTAINER_NAME)"	@echo "Starting container in background: $(CONTAINER_NAME)"

	docker run -d \	docker run -d \

		--name $(CONTAINER_NAME) \		--name $(CONTAINER_NAME) \

		--privileged \		--privileged \

		-v /dev:/dev \		-v /dev:/dev \

		-v $(PWD):/workspace \		-v $(PWD):/workspace \

		-w /workspace \		-w /workspace \

		-p 3333:3333 \		-p 3333:3333 \

		-p 4444:4444 \		-p 4444:4444 \

		$(IMAGE_NAME):$(VERSION) \		$(IMAGE_NAME):$(VERSION) \

		tail -f /dev/null		tail -f /dev/null



# Stop and remove containers# Stop and remove containers

clean:clean:

	@echo "Cleaning up containers and images..."	@echo "Cleaning up containers and images..."

	-docker stop $(CONTAINER_NAME) 2>/dev/null	-docker stop $(CONTAINER_NAME) 2>/dev/null

	-docker rm $(CONTAINER_NAME) 2>/dev/null	-docker rm $(CONTAINER_NAME) 2>/dev/null

	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null

	docker system prune -f	docker system prune -f



# Test the Docker image# Test the Docker image

test:test:

	@echo "Testing Docker image..."	@echo "Testing Docker image..."

	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "which gcc && gcc --version"	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "which gcc && gcc --version"

	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "which cmake && cmake --version"	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "which cmake && cmake --version"

	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "ls -la /opt/stm32-tools.sh"	docker run --rm $(IMAGE_NAME):$(VERSION) /bin/bash -c "ls -la /opt/stm32-tools.sh"



# Install STM32 tools in running container# Install STM32 tools in running container

install-tools:install-tools:

	@echo "Installing STM32 tools..."	@echo "Installing STM32 tools..."

	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --menu	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --menu



# Install specific tool# Install specific tool

install-gnu-arm:install-gnu-arm:

	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-gnu-arm	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-gnu-arm



install-arm-compiler:install-arm-compiler:

	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-arm-compiler	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-arm-compiler



install-stm32cube:install-stm32cube:

	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-stm32cube	docker exec -it $(CONTAINER_NAME) /opt/stm32-tools.sh --install-stm32cube



# Development workflow targets (Git hooks based)# Development workflow targets (Git hooks based)

setup-hooks:setup-hooks:

	@echo "Setting up Git hooks..."	@echo "Setting up Git hooks..."

	./scripts/setup-hooks.sh setup	./scripts/setup-hooks.sh setup

	@echo "Git hooks setup completed!"	@echo "Git hooks setup completed!"



hooks-status:hooks-status:

	@echo "Checking Git hooks status..."	@echo "Checking Git hooks status..."

	./scripts/setup-hooks.sh status	./scripts/setup-hooks.sh status



lint:lint:

	@echo "Running code quality checks via Git hooks..."	@echo "Running code quality checks via Git hooks..."

	@if command -v pre-commit >/dev/null 2>&1; then \	@if command -v pre-commit >/dev/null 2>&1; then \

		pre-commit run --all-files; \		pre-commit run --all-files; \

	else \	else \

		echo "Pre-commit not available, using basic checks..."; \		echo "Pre-commit not available, using basic checks..."; \

		find . -name "*.sh" -exec bash -n {} \; ; \		find . -name "*.sh" -exec bash -n {} \; ; \

	fi	fi



format:format:

	@echo "Formatting code via Git hooks..."	@echo "Formatting code via Git hooks..."

	@if command -v pre-commit >/dev/null 2>&1; then \	@if command -v pre-commit >/dev/null 2>&1; then \

		pre-commit run --all-files; \		pre-commit run --all-files; \

	else \	else \

		echo "Pre-commit not available, manual formatting needed"; \		echo "Pre-commit not available, manual formatting needed"; \

	fi	fi



# VS Code DevContainer setup# VS Code DevContainer setup

devcontainer:devcontainer:

	@echo "Setting up VS Code DevContainer..."	@echo "Setting up VS Code DevContainer..."

	@if [ ! -f .devcontainer/devcontainer.json ]; then \	@if [ ! -f .devcontainer/devcontainer.json ]; then \

		echo "Error: .devcontainer/devcontainer.json not found!"; \		echo "Error: .devcontainer/devcontainer.json not found!"; \

		echo "Make sure DevContainer configuration exists."; \		echo "Make sure DevContainer configuration exists."; \

		exit 1; \		exit 1; \

	fi	fi

	@echo "DevContainer is ready!"	@echo "DevContainer is ready!"

	@echo "Open this folder in VS Code and select 'Reopen in Container'"	@echo "Open this folder in VS Code and select 'Reopen in Container'"



# Development shortcuts# Development shortcuts

dev-setup: build setup-hooksdev-setup: build setup-hooks

	@echo "Development environment setup complete!"	@echo "Development environment setup complete!"



dev-start: run-backgrounddev-start: run-background

	@echo "Development container started in background"	@echo "Development container started in background"

	@echo "Use 'make install-tools' to install STM32 tools"	@echo "Use 'make install-tools' to install STM32 tools"



dev-stop:dev-stop:

	docker stop $(CONTAINER_NAME)	docker stop $(CONTAINER_NAME)

	docker rm $(CONTAINER_NAME)	docker rm $(CONTAINER_NAME)



# Shell into running container# Shell into running container

shell:shell:

	docker exec -it $(CONTAINER_NAME) /bin/bash	docker exec -it $(CONTAINER_NAME) /bin/bash



# View container logs# View container logs

logs:logs:

	docker logs -f $(CONTAINER_NAME)	docker logs -f $(CONTAINER_NAME)



# Check container status# Check container status

status:status:

	@echo "Container Status:"	@echo "Container Status:"

	@docker ps -f name=$(CONTAINER_NAME)	@docker ps -f name=$(CONTAINER_NAME)

	@echo ""	@echo ""

	@echo "Image Information:"	@echo "Image Information:"

	@docker images | grep $(IMAGE_NAME)	@docker images | grep $(IMAGE_NAME)



# Build and test pipeline# Build and test pipeline

ci: build test lintci: build test lint

	@echo "CI pipeline completed successfully!"	@echo "CI pipeline completed successfully!"



# Force rebuild without cache# Force rebuild without cache

rebuild:rebuild:

	docker build --no-cache -t $(IMAGE_NAME):$(VERSION) .	docker build --no-cache -t $(IMAGE_NAME):$(VERSION) .



# Export image# Export image

export:export:

	docker save $(IMAGE_NAME):$(VERSION) | gzip > $(IMAGE_NAME)-$(VERSION).tar.gz	docker save $(IMAGE_NAME):$(VERSION) | gzip > $(IMAGE_NAME)-$(VERSION).tar.gz

	@echo "Image exported to $(IMAGE_NAME)-$(VERSION).tar.gz"	@echo "Image exported to $(IMAGE_NAME)-$(VERSION).tar.gz"



# Import image# Import image

import:import:

	docker load < $(IMAGE_NAME)-$(VERSION).tar.gz	docker load < $(IMAGE_NAME)-$(VERSION).tar.gz



# Show image size and layers# Show image size and layers

inspect:inspect:

	@echo "Image Size and Information:"	@echo "Image Size and Information:"

	docker images $(IMAGE_NAME):$(VERSION)	docker images $(IMAGE_NAME):$(VERSION)

	@echo ""	@echo ""

	@echo "Image Layers:"	@echo "Image Layers:"

	docker history $(IMAGE_NAME):$(VERSION)	docker history $(IMAGE_NAME):$(VERSION)



# Security scan (requires docker scout or similar tool)# Security scan (requires docker scout or similar tool)

security-scan:security-scan:

	@if command -v docker scout >/dev/null 2>&1; then \	@if command -v docker scout >/dev/null 2>&1; then \

		docker scout cves $(IMAGE_NAME):$(VERSION); \		docker scout cves $(IMAGE_NAME):$(VERSION); \

	else \	else \

		echo "Docker Scout not available. Install for security scanning."; \		echo "Docker Scout not available. Install for security scanning."; \

	fi	fi



# Multi-architecture build (requires buildx)# Multi-architecture build (requires buildx)

build-multi:build-multi:

	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(VERSION) .	docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(VERSION) .



# Update base image and rebuild# Update base image and rebuild

update:update:

	docker pull ubuntu:24.04	docker pull ubuntu:24.04

	$(MAKE) rebuild	$(MAKE) rebuild



# Development workflow help# Development workflow help

dev-help:dev-help:

	@echo ""	@echo ""

	@echo "Development Workflow:"	@echo "Development Workflow:"

	@echo "===================="	@echo "===================="

	@echo "1. make dev-setup    - Initial setup (build + Git hooks)"	@echo "1. make dev-setup    - Initial setup (build + Git hooks)"

	@echo "2. make dev-start    - Start development container"	@echo "2. make dev-start    - Start development container"

	@echo "3. make install-tools - Install STM32 tools interactively"	@echo "3. make install-tools - Install STM32 tools interactively"

	@echo "4. make shell        - Access container shell"	@echo "4. make shell        - Access container shell"

	@echo "5. make dev-stop     - Stop development container"	@echo "5. make dev-stop     - Stop development container"

	@echo ""	@echo ""

	@echo "DevContainer Workflow:"	@echo "DevContainer Workflow:"

	@echo "====================="	@echo "====================="

	@echo "1. make devcontainer - Verify DevContainer setup"	@echo "1. make devcontainer - Verify DevContainer setup"

	@echo "2. Open folder in VS Code"	@echo "2. Open folder in VS Code"

	@echo "3. Select 'Reopen in Container'"	@echo "3. Select 'Reopen in Container'"

	@echo "4. Run tools installation from integrated terminal"	@echo "4. Run tools installation from integrated terminal"