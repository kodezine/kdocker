# GitHub Actions Workflows

This directory contains CI/CD workflows for building, testing, and releasing the Docker image.

## Workflows

### 1. `docker-build.yml` - Build and Push
**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Tags matching `v*.*.*`
- Manual workflow dispatch

**Actions:**
- Builds Docker image for `linux/amd64`
- Pushes to GitHub Container Registry (ghcr.io)
- Creates multiple tags (version, major.minor, major, latest, sha)
- Uses GitHub Actions cache for faster builds
- Generates build attestation

### 2. `docker-release.yml` - Release
**Triggers:**
- GitHub Release published

**Actions:**
- Builds and pushes release image
- Creates release-specific tags
- Generates detailed release notes
- Updates release with Docker image information
- Includes verification commands

### 3. `docker-test.yml` - Testing
**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`

**Actions:**
- Builds image without pushing
- Tests all major components (GCC, CMake, Python, etc.)
- Tests ARM toolchains
- Tests 32-bit compilation
- Verifies cross-compilation works

## Usage

### Creating a Release

1. Create and push a tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. Create a GitHub Release from the tag

3. The `docker-release.yml` workflow will:
   - Build the image
   - Push to ghcr.io with tags: `v1.0.0`, `1.0`, `1`, `latest`
   - Update the release with Docker image info

### Using the Published Image

```bash
# Pull the image
docker pull ghcr.io/YOUR_USERNAME/dev-docker:latest

# Or specific version
docker pull ghcr.io/YOUR_USERNAME/dev-docker:v1.0.0

# Run the container
docker run -it --rm ghcr.io/YOUR_USERNAME/dev-docker:latest
```

### Manual Workflow Dispatch

Go to Actions → Build and Release Docker Image → Run workflow

## Secrets Required

The workflows use the following secrets (automatically provided by GitHub):
- `GITHUB_TOKEN` - For pushing to GitHub Container Registry

No additional secrets need to be configured.

## Permissions

The workflows require the following permissions:
- `contents: read` - Read repository contents
- `packages: write` - Push to GitHub Container Registry
- `attestations: write` - Generate build attestations
- `id-token: write` - For attestation signing

These are configured in the workflow files.

## Caching

The workflows use GitHub Actions cache to speed up builds:
- Docker layer caching with `type=gha`
- Reuses cached layers between builds
- Significantly reduces build time for subsequent runs

## Platform Support

Currently building for:
- `linux/amd64` (x86_64)

To add ARM64 support, modify the `platforms` in the workflow:
```yaml
platforms: linux/amd64,linux/arm64
```
