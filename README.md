# istio-jwt-validator-wasm

> **This repository is ARCHIVED.** See [Archive Notice](#archive-notice) below.

[![CI](https://github.com/Klazomenai/istio-jwt-validator-wasm/actions/workflows/ci.yaml/badge.svg)](https://github.com/Klazomenai/istio-jwt-validator-wasm/actions/workflows/ci.yaml)
[![Go Report Card](https://goreportcard.com/badge/github.com/Klazomenai/istio-jwt-validator-wasm)](https://goreportcard.com/report/github.com/Klazomenai/istio-jwt-validator-wasm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Envoy WASM plugin for JWT validation endpoint with HttpOnly cookie management.

## Archive Notice

**Decision Date**: 2026-02-04
**Status**: Superseded

### Why This Repository Is Archived

This WASM plugin was intended to implement a `/api/validate` endpoint with CSRF validation and HttpOnly cookie management as an Envoy WASM filter running inside the Istio Gateway. After architectural analysis, this approach was rejected for the following reasons:

1. **Architectural mismatch**: WASM plugins are designed for request filtering (intercepting and modifying requests in transit), not for implementing API endpoints. An `/api/validate` endpoint with cookie management is a service responsibility, not a filter responsibility.

2. **Unnecessary middleware layer**: The planned flow (`client → WASM plugin → jwt-auth-service`) added an extra hop with no added value. The WASM plugin would have simply proxied requests to jwt-auth-service.

3. **Code duplication with [istio-jwt-wasm](https://github.com/Klazomenai/istio-jwt-wasm)**: Both repositories contained near-identical JWT parsing logic for JTI extraction (`pkg/jwt/extractor.go` vs `pkg/jwt/parser.go`), duplicating base64url decoding and claim extraction without signature verification.

4. **Incomplete implementation**: Only the JWT parsing utilities and CI/CD infrastructure were completed. The core WASM filter logic (`main.go`), CSRF validation (`pkg/csrf/`), and cookie management (`pkg/cookie/`) were never implemented.

### Where This Functionality Moved

The `/api/validate` endpoint, CSRF validation, and HttpOnly cookie management were implemented directly in [jwt-auth-service](https://github.com/Klazomenai/jwt-auth-service) as native Go HTTP handlers (shipped in v0.1.3-alpha.0).

### Active Repositories

| Repository | Purpose | Status |
|-----------|---------|--------|
| [jwt-auth-service](https://github.com/Klazomenai/jwt-auth-service) | JWT token lifecycle: creation, validation, revocation, auto-renewal, `/api/validate` + cookies | Active (v0.1.3-alpha.0) |
| [istio-jwt-wasm](https://github.com/Klazomenai/istio-jwt-wasm) | Gateway-level JWT revocation enforcement via Envoy WASM filter | Active (v0.0.1-alpha) |

### What Remains Useful

- **Nix flakes CI/CD patterns**: Reproducible WASM + OCI image builds via pure Nix (`flake.nix`)
- **Proxy-WASM Go SDK skeleton**: Boilerplate for `vmContext`/`pluginContext`/`httpContext` lifecycle
- **JWT parsing utilities**: `pkg/jwt/parser.go` with comprehensive test coverage

---

## Original Overview

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
