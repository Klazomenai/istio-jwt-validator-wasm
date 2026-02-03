# istio-jwt-validator-wasm

[![CI](https://github.com/Klazomenai/istio-jwt-validator-wasm/actions/workflows/ci.yaml/badge.svg)](https://github.com/Klazomenai/istio-jwt-validator-wasm/actions/workflows/ci.yaml)
[![Go Report Card](https://goreportcard.com/badge/github.com/Klazomenai/istio-jwt-validator-wasm)](https://goreportcard.com/report/github.com/Klazomenai/istio-jwt-validator-wasm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Envoy WASM plugin for JWT validation endpoint with HttpOnly cookie management.

> **⚠️ Alpha Status**: v0.1.0-alpha - Not production ready.

## Overview

WASM plugin that validates JWT tokens via two-stage authentication:
1. CSRF token validation
2. JWT signature and revocation check

Sets HttpOnly session cookie on successful validation.

## Development Setup

### Using devenv (Recommended)

[devenv](https://devenv.sh) provides a reproducible development environment with Go 1.25, testing tools, and pre-commit hooks.

**Installation**:
```bash
# Install devenv (requires Nix)
# See: https://devenv.sh/getting-started/

# Enter development environment:
devenv shell

# Or use direnv for automatic activation:
direnv allow
```

**Available commands**:
```bash
build-wasm        # Build WASM plugin (native Go WASM)
test              # Run tests with coverage
test-coverage     # Generate HTML coverage report
lint              # Run golangci-lint
```

### Manual Setup

**Requirements**: Go 1.25+

```bash
# Install dependencies
go mod download

# Build WASM plugin
make build

# Run tests
make test

# Output: plugin.wasm
```

**Build details**: Uses native Go WASM compiler (`GOOS=wasip1 GOARCH=wasm`), not TinyGo.

## CI/CD

This project uses GitHub Actions for continuous integration and deployment.

### Workflows

**CI Pipeline** (`.github/workflows/ci.yaml`)
- **Triggers**: Push to `main`, Pull Requests
- **Jobs**:
  - **Lint**: gofmt, go vet, golangci-lint (7 linters)
  - **Security**: gosec (code patterns), govulncheck (CVEs)
  - **Test**: Unit tests with race detection, 70% coverage threshold
  - **Build**: WASM artifact with SHA256 checksum

**Release** (`.github/workflows/release.yaml`)
- **Triggers**: Version tags (`v*`)
- **Actions**:
  - Build WASM and OCI image with pure Nix (reproducible)
  - Push to `ghcr.io/klazomenai/istio-jwt-validator-wasm:VERSION`
  - Create GitHub Release with WASM binary
  - Push `latest` tag for stable releases (not alpha/beta)

**Manual Build** (`.github/workflows/manual-build.yaml`)
- **Triggers**: Manual dispatch from Actions UI
- **Actions**: Build and push custom branch builds for testing
- **Tag format**: `{branch}-{short-sha}` (e.g., `feature-auth-abc1234`)

### Reproducible Builds

All releases are built with [Nix flakes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html) for full reproducibility:

```bash
# Reproduce any release build locally
nix build github:Klazomenai/istio-jwt-validator-wasm/v0.1.0-alpha.1#wasm

# Verify the output matches the published release
sha256sum result/plugin.wasm
```

### Dependency Updates

[Dependabot](https://docs.github.com/en/code-security/dependabot) automatically creates PRs for:
- Go module updates (weekly)
- GitHub Actions updates (weekly)

## Configuration

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: jwt-validator
  namespace: istio-system
spec:
  url: oci://ghcr.io/klazomenai/istio-jwt-validator-wasm:v0.1.0-alpha.0
  pluginConfig:
    cluster: "outbound|8080||jwt-service.namespace.svc.cluster.local"
    validateEndpoint: "/api/validate"
    csrfHeaderName: "X-CSRF-Token"
    cookieName: "session"
    cookieDomain: ".example.com"
```

## License

MIT - see [LICENSE](LICENSE)
